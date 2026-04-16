class BulkExport::Process < ApplicationInteractor
  def initialize(bulk_export:)
    @bulk_export = bulk_export

    super
  end

  def perform
    logger.info "Found bulk_export for \n\tuser=#{@bulk_export.user.login}"
    logger.info "\tfrom collection=#{@bulk_export.collection.title}" if @bulk_export.collection.present?
    logger.info @bulk_export.attributes.pretty_inspect

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

  def export_to_zip
    works_scope = Work.includes(pages: [:notes, { page_versions: :user }])
    works =
      if @bulk_export.work.present?
        works_scope.where(id: @bulk_export.work.id)
      elsif @bulk_export.document_set.present?
        works_scope.where(id: @bulk_export.document_set.works.pluck(:id))
      elsif @bulk_export.collection.present?
        works_scope.where(collection_id: @bulk_export.collection.id)
      else
        works_scope.none
      end

    zip_filename = "export_#{@bulk_export.id}.zip"

    Tempfile.create([zip_filename, '.zip']) do |tmpfile|
      Zip::OutputStream.open(tmpfile.path) do |out|
        write_work_exports(works, out, @bulk_export.user, @bulk_export)
      end

      tmpfile.rewind

      @bulk_export.output.attach(
        io: tmpfile,
        filename: zip_filename,
        content_type: 'application/zip'
      )
    end
  end
end
