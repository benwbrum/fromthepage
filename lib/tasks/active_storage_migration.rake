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

  desc 'Delete migrated legacy images. Usage: [slug or all,start_from_id,batch_size,dry_run] (dry_run defaults to true)'
  task :delete_migrated_page_images, [:slug, :start_from_id, :batch_size, :dry_run] => :environment do |_task, args|
    args.with_defaults(start_from_id: '1', batch_size: '1000', dry_run: 'true')

    slug = args[:slug]
    abort 'Usage: rake fromthepage:delete_migrated_page_images[slug or all,start_from_id,batch_size,dry_run]' if slug.blank?
    abort 'start_from_id must be a positive integer.' unless args[:start_from_id].match?(/\A[1-9]\d*\z/)
    abort 'batch_size must be a positive integer.' unless args[:batch_size].match?(/\A[1-9]\d*\z/)
    abort 'dry_run must be true or false.' unless %w[true false].include?(args[:dry_run])

    dry_run = args[:dry_run] == 'true'
    next_id = args[:start_from_id].to_i
    batch_size = args[:batch_size].to_i

    pages = if slug == 'all'
              Page.all
    else
              user = User.find_by(slug: slug)
              collection = Collection.find_by(slug: slug)

              if user && collection
                abort "Both a user and collection have the slug #{slug.inspect}; no files were deleted."
              end
              abort "No user or collection found with slug #{slug.inspect}." unless collection || user

              collection ? collection.pages : Page.joins(:work).where(works: { owner_user_id: user.id })
    end
    # title and position are read by Page's after_initialize callback.
    pages = pages.where.not(base_image: [nil, '']).select(:id, :base_image, :title, :position)
                 .preload(image_attachment: :blob)

    deleted_files = 0
    deleted_bytes = 0
    processed_pages = 0
    public_root = Rails.root.join('public').expand_path
    $stdout.sync = true
    puts "Starting image cleanup: scope=#{slug}, start_from_id=#{next_id}, batch_size=#{batch_size}, dry_run=#{dry_run}"

    # Fetch each batch only after verifying the connection: filesystem/storage work
    # can leave it idle longer than the database's wait_timeout. Avoid OFFSET and
    # the query cache so memory usage stays bounded over millions of pages.
    Page.uncached do
      loop do
        batch = ActiveRecord::Base.connection_pool.with_connection do |connection|
          connection.verify!
          pages.where('pages.id >= ?', next_id).reorder('pages.id ASC').limit(batch_size).to_a
        end
        break if batch.empty?

        batch.each do |page|
          legacy_path = public_root.join(page.base_image.sub(%r{\A.*public/}, '')).cleanpath
          abort "Page ##{page.id}: path outside public: #{legacy_path}" unless legacy_path.to_s.start_with?("#{public_root}/")

          extension = File.extname(legacy_path)
          thumbnail_path = legacy_path.sub(/#{Regexp.escape(extension)}\z/, "_thumb#{extension}")
          paths = [legacy_path, thumbnail_path].uniq.select { |path| File.file?(path) || File.symlink?(path) }
          next if paths.empty?
          next unless page.image.attached?

          # An attachment row alone does not guarantee that its uploaded object exists.
          blob = page.image.blob
          unless blob.service.exist?(blob.key)
            warn "Page ##{page.id}: ActiveStorage object missing; keeping legacy files."
            next
          end

          paths.each do |path|
            # Follow linked directories, as used for Capistrano's shared uploads.
            # lstat/delete operate on the link itself if the final file is a symlink.
            bytes = File.lstat(path).size
            File.delete(path) unless dry_run

            deleted_files += 1
            deleted_bytes += bytes
          end
        end

        processed_pages += batch.length
        next_id = batch.last.id + 1
        puts "Processed #{processed_pages} pages; #{dry_run ? 'would delete' : 'deleted'} #{deleted_files} files; next start_from_id=#{next_id}"
      end
    end

    deleted_mebibytes = deleted_bytes.fdiv(1024 * 1024)
    puts format("#{dry_run ? 'Would delete' : 'Deleted'} %<files>d files (logical size %<mib>.2f MiB).",
                files: deleted_files,
                mib: deleted_mebibytes)
  rescue StandardError => e
    warn "Cleanup stopped: #{e.class}: #{e.message}. Resume with start_from_id=#{next_id}; repeating a batch is safe."
    raise
  end
end
