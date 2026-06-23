class StripBrTagsFromAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    AiTranscription.where.not(source_text: nil).find_each do |transcription|
      transcription.normalize_source_text
      transcription.save! if transcription.changed?
    end
  end
end
