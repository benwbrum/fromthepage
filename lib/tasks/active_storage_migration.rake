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

    attached_page_ids = ActiveStorage::Attachment.where(record_type: 'Page', name: 'image').select(:record_id)
    pages = pages.where.not(base_image: [nil, ''])
                 .where.not(id: attached_page_ids)

    log(
      logger: logger,
      msg: "Starting migration from Page ID #{start_from_id}"
    )

    pages.find_each do |page|
      log(
        logger: logger,
        msg: "Processing Page ##{page.id}"
      )

      unless page.work
        log(
          logger: logger,
          msg: "\tPage ##{page.id}: no associated work. Skipping..."
        )

        next
      end

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

  # NOTE: Use only the params you intend to scope the migration.
  # start_from_id: Adding this param means we start from page_id until the end
  # page_ids: Adding this param means we are scoping the migration to the given page_ids. use "-" separator
  # collection_id: Adding this param means we are scoping the migration to the pages within the given collection
  # work_id: Adding this param means we are scoping the migration to the pages within the given work
  desc 'Delete legacy page images migrated to ActiveStorage'
  task :delete_migrated_page_images,
    [:dry_run, :start_from_id, :page_ids, :collection_id, :work_id] => :environment do |_t, args|
      require 'logger'
      require 'fileutils'

      abort 'dry_run must be true or false.' unless ['true', 'false'].include?(args[:dry_run])

      dry_run = args[:dry_run] == 'true'

      start_from_id = args[:start_from_id].to_i
      start_from_id = 1 if start_from_id.zero?

      log_dir = Rails.root.join('tmp', 'migration')
      FileUtils.mkdir_p(log_dir)

      logger = Logger.new(log_dir.join('deleted_migrated_page_images.log'))

      log_msg = lambda do |msg|
        logger.info(msg)
        puts msg
      end

      log_msg.call('*** RUNNING IN DRY RUN MODE. NO FILES WILL BE DELETED. ***') if dry_run

      if args[:page_ids].present?
        pages = Page.where(id: args[:page_ids].split('-'))
      elsif args[:work_id].present?
        work = Work.find(args[:work_id])
        pages = work.pages
      elsif args[:collection_id].present?
        collection = Collection.find(args[:collection_id])
        pages = collection.pages
      else
        pages = Page.where(id: start_from_id..Float::INFINITY)
      end

      attached_page_ids = ActiveStorage::Attachment.where(record_type: 'Page', name: 'image').select(:record_id)

      pages = pages.where.not(base_image: [nil, ''])
                   .where(id: attached_page_ids)

      log_msg.call("Starting deletion from Page ID #{start_from_id}")

      deleted_files = 0
      deleted_bytes = 0

      pages.find_each do |page|
        next unless page.image.attached?

        relative_path = page.base_image.to_s.sub(%r{\A.*public/?}, '')
        legacy_path = Rails.root.join('public', relative_path).to_s

        extension = File.extname(legacy_path)
        thumbnail_path = legacy_path.sub(/#{Regexp.escape(extension)}\z/, "_thumb#{extension}")

        [legacy_path, thumbnail_path].each do |path|
          next unless File.file?(path) || File.symlink?(path)

          begin
            bytes = File.lstat(path).size

            if dry_run
              log_msg.call("[DRY RUN] Would delete: #{path} (#{bytes} bytes)")
            else
              File.delete(path)
              log_msg.call("Deleted: #{path} (#{bytes} bytes)")
            end

            deleted_files += 1
            deleted_bytes += bytes
          rescue SystemCallError => e
            abort "Could not process or delete #{path}: #{e.message}"
          end
        end
      end

      deleted_mebibytes = deleted_bytes.fdiv(1024 * 1024)
      action = dry_run ? 'Would delete' : 'Deleted'

      summary = format('%<action>s %<files>d files and freed %<mib>.2f MiB.',
        action: action,
        files: deleted_files,
        mib: deleted_mebibytes)

      log_msg.call(summary)
    end
end
