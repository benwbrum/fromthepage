class BulkExport::Lib::Exporter
  include XmlSourceProcessor

  BASE_PATH = '/tmp/fromthepage_exports'.freeze

  def initialize(bulk_export:)
    @bulk_export = bulk_export
    @export_user = @bulk_export.user
  end

  def perform
    Zip::OutputStream.open(zip_file_name) do |output|
      if @bulk_export.owner_mailing_list
        BulkExport::Lib::OwnerMailingListCsv.export(
          output,
          @export_user
        )
      end

      if @bulk_export.owner_detailed_activity
        BulkExport::Lib::OwnerDetailedActivityCsv.export(
          output,
          @export_user,
          @bulk_export.report_arguments
        )
      end

      if @bulk_export.admin_searches
        BulkExport::Lib::AdminSearchesCsv.export(
          output,
          report_arguments: bulk_export.report_arguments
        )
      end

      output.close
    end
  end

  private

  def works
    return @works if defined?(@works)

    @works = if @bulk_export.work
               Work.where(id: @bulk_export.work_id).includes(pages: [:notes, { page_versions: :user }])
             elsif @bulk_export.document_set
               @bulk_export.document_set.works.includes(pages: [:notes, { page_versions: :user }])
             elsif @bulk_export.collection
               @bulk_export.collection.works.includes(pages: [:notes, { page_versions: :user }])
             else
               Work.none
             end

    @works
  end

  def zip_file_path
    FileUtils.mkdir_p(BASE_PATH)

    BASE_PATH
  end

  def zip_file_name
    File.join(zip_file_path, "export_#{@bulk_export.id}.zip")
  end
end
