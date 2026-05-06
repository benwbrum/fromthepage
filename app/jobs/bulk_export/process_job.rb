class BulkExport::ProcessJob < ApplicationJob
  queue_as :bulk_exports

  retry_on StandardError, attempts: 1

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, bulk_export_id:)
    bulk_export = BulkExport.find(bulk_export_id)
    bulk_export.update!(status: :queued)

    result = BulkExport::Process.new(bulk_export: bulk_export).call

    if result.success? && SMTP_ENABLED
      begin
        UserMailer.bulk_export_finished(result.bulk_export).deliver!
      rescue StandardError => e
        raise "SMTP Failed: Exception: #{e.message}"
      end
    elsif !result.success?
      result.bulk_export.update!(status: :error)

      raise result.full_errors
    end
  end
end
