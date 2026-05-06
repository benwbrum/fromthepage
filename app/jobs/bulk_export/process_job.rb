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
      error = result.full_errors

      error_message =
        if error.respond_to?(:backtrace)
          "#{error.message}\n#{error.backtrace.join("\n")}"
        else
          error.to_s
        end

      path = result.bulk_export.log_file

      if path.present?
        FileUtils.mkdir_p(File.dirname(path))

        File.open(path, 'a') do |f|
          f.puts "\n=== #{Time.current} ==="
          f.puts error_message
        end
      end

      raise result.full_errors
    end
  end
end
