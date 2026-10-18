class PreserveAiAccuracyStatisticsPrecision < ActiveRecord::Migration[7.2]
  STATISTIC_COLUMNS = %i[
    verbatim_cer verbatim_wer text_cer text_wer verbatim_non_stopword_accuracy
  ].freeze

  def up
    change_table :ai_transcriptions, bulk: true do |t|
      STATISTIC_COLUMNS.each do |column|
        # Preserve the original ten integer digits while adding two decimal places.
        t.change column, :decimal, precision: 12, scale: 2
      end
    end
  end

  def down
    change_table :ai_transcriptions, bulk: true do |t|
      STATISTIC_COLUMNS.each do |column|
        t.change column, :decimal, precision: 10, scale: 0
      end
    end
  end
end
