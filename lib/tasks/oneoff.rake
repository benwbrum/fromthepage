namespace :oneoff do
  desc 'Remediate duplicate enqueued AI transcription jobs'
  task remediate_duplicate_enqueued_ai_transcription_jobs: :environment do
    duplicates = AiTranscription
      .where(status: :processing)
      .group(:page_id)
      .having('COUNT(*) > 1')
      .count

    destroyed_ids = []

    duplicates.keys.each do |page_id|
      records = AiTranscription
        .where(page_id: page_id, status: :processing)
        .order(created_at: :desc)

      keeper = records.first
      to_delete = records.offset(1)

      to_delete.find_each do |rec|
        destroyed_ids << rec.id
        rec.destroy!
      end
    end

    destroyed_ids

    jobs = SolidQueue::Job
      .where(class_name: 'AiTranscription::GenerateJob')
      .where(finished_at: nil)

    jobs_to_delete = jobs.select do |job|
      args = job.arguments['arguments']

      ai_id = args.dig(0, 'ai_transcription_id')
      destroyed_ids.include?(ai_id)
    end

    jobs_to_delete.each(&:destroy!)

    SolidQueue::ClaimedExecution
      .left_joins(:job)
      .where(solid_queue_jobs: { id: nil })
      .delete_all

    SolidQueue::ReadyExecution
      .left_joins(:job)
      .where(solid_queue_jobs: { id: nil })
      .delete_all

    SolidQueue::ScheduledExecution
      .left_joins(:job)
      .where(solid_queue_jobs: { id: nil })
      .delete_all
  end
end
