class IncreaseTextSizeOnAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    change_table :ai_transcriptions, bulk: true do |t|
      t.change :source_text, :longtext
      t.change :prompt, :longtext
      t.change :reasoning, :longtext
    end
  end
end
