class AddStatisticsToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    change_table :ai_transcriptions, bulk: true do |t|
      t.decimal :verbatim_cer, null: true
      t.decimal :verbatim_wer, null: true
      t.decimal :verbatim_non_stopword_accuracy, null: true

      t.decimal :text_cer, null: true
      t.decimal :text_wer, null: true
    end
  end
end
