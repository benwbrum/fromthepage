class AddStatusToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    change_table :ai_transcriptions, bulk: true do |t|
      t.string :status, default: 'new', null: false
    end
  end
end
