class AddTranscriptionJsonFieldToPagesTable < ActiveRecord::Migration[6.1]
  def change
    change_table :pages, bulk: true do |t|
      t.json :transcription_json, null: true
    end
  end
end
