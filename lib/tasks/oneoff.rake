namespace :oneoff do
  desc 'Remediate duplicate and dead jobs'
  task remediate_duplicate_jobs: :environment do
    active_process_pids = [
      # WORKERS
      2074926,
      2074932,

      # SCHEDULER
      2074936,

      # DISPATCHERS
      2074922
    ]

    active_processes = SolidQueue::Process
      .where(id: active_process_pids)

    stale_processes = SolidQueue::Process
      .where.not(id: active_processes.pluck(:id))

    stale_claimed = SolidQueue::ClaimedExecution
      .where(process_id: stale_processes.pluck(:id))

    jobs = SolidQueue::Job.where(id: stale_claimed.pluck(:job_id)).index_by(&:id)

    stale_claimed.find_each do |claim|
      job = jobs[claim.job_id]

      if job.nil?
        claim.delete
        next
      end

      args = job.arguments
      payload = args['arguments']&.first || {}

      case job.class_name
      when 'BulkExport::ProcessJob'
        bulk_export_id = payload['bulk_export_id']
        record = BulkExport.find_by(id: bulk_export_id)

        if record&.status.in?(['new', 'queued', 'processing'])
          record.update!(status: 'error')
        end
      when 'AiTranscription::GenerateJob'
        ai_id = payload['ai_transcription_id']
        record = AiTranscription.find_by(id: ai_id)

        if record&.status.in?(['new', 'processing'])
          record.update!(status: 'error')
        end
      else
        next
      end

      job.update!(finished_at: Time.current)

      SolidQueue::FailedExecution.create!(
        job_id: job.id,
        error: 'Reconciled as failed due to stale process cleanup',
        created_at: Time.current
      )

      claim.delete
    end

    stale_processes.delete_all
  end
end
