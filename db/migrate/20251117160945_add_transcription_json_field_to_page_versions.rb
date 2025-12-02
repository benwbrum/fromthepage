class AddTranscriptionJsonFieldToPageVersions < ActiveRecord::Migration[7.2]
  def change
    change_table :page_versions, bulk: true do |t|
      t.json :transcription_json, null: true
    end
  end
end
