class ReplaceNbspInAiTranscriptions < ActiveRecord::Migration[7.2]
  disable_ddl_transaction!

  def up
    AiTranscription.where("source_text LIKE ?", "%\u00A0%").find_each do |ai_transcription|
      ai_transcription.update_column(:source_text, ai_transcription.source_text.gsub("\u00A0", ' '))
    end
  end

  def down
    # Irreversible: we cannot reliably distinguish replaced spaces from original spaces
    raise ActiveRecord::IrreversibleMigration
  end
end
