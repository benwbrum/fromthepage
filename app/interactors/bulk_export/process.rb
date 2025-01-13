class BulkExport::Process < ApplicationInteractor
  def initialize(bulk_export:)
    @bulk_export = bulk_export

    super
  end

  def perform
    BulkExport::Lib::Exporter.new(
      bulk_export: @bulk_export
    ).perform
  end
end
