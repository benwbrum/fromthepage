class AddStatisticsToAiTranscriptions < ActiveRecord::Migration[7.2]
  def change
    change_table :ai_transcriptions, bulk: true do |t|
      t.decimal :verbatim_cer, null: true
      t.decimal :verbatim_cer_distance, null: true
      t.decimal :verbatim_cer_length, null: true
      t.decimal :verbatim_wer, null: true
      t.decimal :verbatim_wer_distance, null: true
      t.decimal :verbatim_wer_length, null: true

      t.decimal :text_cer, null: true
      t.decimal :text_cer_distance, null: true
      t.decimal :text_cer_length, null: true
      t.decimal :text_wer, null: true
      t.decimal :text_wer_distance, null: true
      t.decimal :text_wer_length, null: true

      t.decimal :verbatim_non_stopword_accuracy, null: true
    end
  end
end
