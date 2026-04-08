class BulkExport::ProcessJob < ApplicationJob
  queue_as :bulk_exports

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, bulk_export_id:)
    bulk_export = BulkExport.find(bulk_export_id)
    bulk_export.update!(status: :queued)

    result = BulkExport::Process.new(bulk_export: bulk_export).call

    raise result.full_errors unless result.success?
  end
end
