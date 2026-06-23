class StripBrTagsFromAiTranscriptions < ActiveRecord::Migration[7.2]
  def up
    AiTranscription.where.not(source_text: nil).find_each do |transcription|
      transcription.normalize_source_text
      transcription.save! if transcription.changed?
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
