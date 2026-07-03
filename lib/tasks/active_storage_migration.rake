namespace :fromthepage do
  # NOTE: Use only the params you intend to scope the migration.
  # start_from_id: Adding this param means we start from page_id until the end
  # page_ids: Adding this param means we are scoping the migration to the given page_ids. use "-" separator
  # collection_id: Adding this param means we are scoping the migration to the pages within the given collection
  # work_id: Adding this param means we are scoping the migration to the pages within the given work
  desc 'Migrate page images to ActiveStorage. Usage: [start_from_id, page_ids, collection_id, work_id]'
  task :migrate_page_images_to_active_storage,
    [:start_from_id, :page_ids, :collection_id, :work_id] => :environment do |_t, args|
    require 'logger'
    require 'fileutils'

    start_from_id = args[:start_from_id].to_i
    start_from_id = 1 if start_from_id.zero?

    log_dir = Rails.root.join('tmp', 'migration')
    FileUtils.mkdir_p(log_dir)

    logger = Logger.new(
      Rails.root.join('tmp', 'migration', 'migrate_page_images_to_active_storage.log')
    )

    def log(logger:, msg:)
      logger.info(msg)
      puts msg
    end

    if args[:page_ids].present?
      pages = Page.where(id: args[:page_ids].split('-'))
    elsif args[:work_id].present?
      work = Work.find(args[:work_id])
      pages = work.pages
    elsif args[:collection_id]
      collection = Collection.find(args[:collection_id])
      pages = collection.pages
    else
      pages = Page.where(id: start_from_id..Float::INFINITY)
    end

    pages = pages.where.not(base_image: [nil, ''])

    log(
      logger: logger,
      msg: "Starting migration from Page ID #{start_from_id}"
    )

    pages.find_each do |page|
      log(
        logger: logger,
        msg: "Processing Page ##{page.id}"
      )

      if page.image.attached?
        log(
          logger: logger,
          msg: "\tPage ##{page.id} already has ActiveStorage "
        )

        next
      end

      legacy_path = File.join(
        Rails.root,
        'public',
        page.base_image.sub(%r{\A.*public/}, '')
      )

      unless File.exist?(legacy_path)
        log(
          logger: logger,
          msg: "\tPage ##{page.id}: file #{legacy_path} does not exist. Skipping..."
        )

        next
      end
      extension = File.extname(legacy_path).downcase

      content_type =
        case extension
        when '.jpg', '.jpeg'
          'image/jpeg'
        when '.png'
          'image/png'
        when '.gif'
          'image/gif'
        when '.webp'
          'image/webp'
        else
          'application/octet-stream'
        end

      File.open(legacy_path) do |file|
        page.image.attach(
          io: file,
          filename: File.basename(legacy_path),
          content_type: content_type
        )
      end

      log(
        logger: logger,
        msg: "\tPage ##{page.id} migrated"
      )
    rescue => e
      log(
        logger: logger,
        msg: "Failed Page ##{page.id}: #{e.class} - #{e.message}"
      )

      raise e
    end

    log(
      logger: logger,
      msg: 'Migration complete'
    )
  end
end

namespace :fromthepage do
  desc 'Delete legacy page images migrated to ActiveStorage for a user or collection slug'
  task :delete_migrated_page_images, [:slug] => :environment do |_task, args|
    require 'open3'

    slug = args[:slug]
    abort 'Usage: rake fromthepage:delete_migrated_page_images[slug]' if slug.blank?

    user = User.find_by(slug: slug)
    collection = Collection.find_by(slug: slug)

    if user && collection
      abort "Both a user and collection have the slug #{slug.inspect}; no files were deleted."
    end

    owner = collection || user
    abort "No user or collection found with slug #{slug.inspect}." unless owner

    pages = if collection
              collection.pages
    else
              Page.joins(:work).where(works: { owner_user_id: user.id })
    end
    pages = pages.where.not(base_image: [nil, ''])

    deleted_files = 0
    deleted_bytes = 0

    pages.find_each do |page|
      next unless page.image.attached?

      legacy_path = Rails.root.join(
        'public',
        page.base_image.sub(%r{\A.*public/?}, '')
      )
      extension = File.extname(legacy_path)
      thumbnail_path = legacy_path.sub(/#{Regexp.escape(extension)}\z/, "_thumb#{extension}")

      [legacy_path, thumbnail_path].each do |path|
        next unless File.file?(path) || File.symlink?(path)

        output, status = Open3.capture2e('du', '-b', '--', path.to_s)
        abort "Could not read the size of #{path}: #{output}" unless status.success?

        bytes = output.split.first.to_i
        abort "Could not delete #{path}." unless system('rm', '--', path.to_s)

        deleted_files += 1
        deleted_bytes += bytes
      end
    end

    deleted_mebibytes = deleted_bytes.fdiv(1024 * 1024)
    puts format('Deleted %<files>d files and freed %<mib>.2f MiB.',
                files: deleted_files,
                mib: deleted_mebibytes)
  end
end
