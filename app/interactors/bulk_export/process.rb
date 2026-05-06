class BulkExport::Process < ApplicationInteractor
  def initialize(bulk_export:)
    @bulk_export = bulk_export

    super
  end

  def perform
    logger.info "Found bulk_export for \n\tuser=#{@bulk_export.user.login}"
    logger.info "\tfrom collection=#{@bulk_export.collection.title}" if @bulk_export.collection.present?
    logger.info @bulk_export.attributes.pretty_inspect

    @bulk_export.custom_logger = logger

    @bulk_export.update!(status: :processing)

    @bulk_export.export_to_zip

    @bulk_export.update!(status: :finished)

    logger.info "Finished bulk_export for \n\tuser=#{@bulk_export.user.login}"
    logger.info "\tfrom collection=#{@bulk_export.collection.title}" if @bulk_export.collection.present?
    logger.info @bulk_export.attributes.pretty_inspect
  rescue StandardError => e
    @bulk_export.update!(status: :error)
    logger.error e.full_message(highlight: false)

    raise
  ensure
    if SMTP_ENABLED
      begin
        UserMailer.bulk_export_finished(@bulk_export).deliver!
      rescue StandardError => e
        logger.error "SMTP Failed: Exception: #{e.message}"
      end
    end

    logger&.close
  end

  private

  def logger
    return @logger if defined?(@logger)

    FileUtils.mkdir_p(File.dirname(@bulk_export.log_file))

    @logger = Logger.new(@bulk_export.log_file)
    @logger.level = Logger::INFO
    @logger.formatter = proc do |severity, datetime, progname, msg|
      "#{msg}\n"
    end

    @logger
  end
end
