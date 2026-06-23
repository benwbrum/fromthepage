class StripBrTagsFromAiTranscriptions < ActiveRecord::Migration[7.2]
  def up
    AiTranscription.where.not(source_text: nil).find_each do |transcription|
      normalized_text = transcription.source_text
                                   .gsub(/<br\s*\/?>/i, "\n")
                                   .gsub('&nbsp;', ' ')

      transcription.update_column(:source_text, normalized_text) unless normalized_text == transcription.source_text
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
