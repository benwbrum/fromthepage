namespace :fromthepage do
  desc 'Migrate page images to ActiveStorage'
  task :migrate_page_images_to_active_storage, [:start_from_id] => :environment do |_t, args|
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

    pages = Page.where(id: start_from_id..Float::INFINITY)
                .where.not(base_image: [nil, ''])

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
