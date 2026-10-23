class AddTranscriptionJsonToAiTranscriptions < ActiveRecord::Migration[7.1]
  def change
    add_column :ai_transcriptions, :transcription_json, :text, limit: 4294967295
  end
end
