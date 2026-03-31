namespace :oneoff do
  desc 'Remediate blank ai_transcription records'
  task remediate_blank_ai_transcription_records: :environment do
    bad_records = AiTranscription.where("(source_text IS NULL OR source_text = '') AND (reasoning IS NULL OR reasoning = '')").where(status: :finished)
    bad_records.update_all(status: :error)
  end
end
