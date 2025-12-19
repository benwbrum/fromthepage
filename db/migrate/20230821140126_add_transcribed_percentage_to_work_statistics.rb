class AddTranscribedPercentageToWorkStatistics < ActiveRecord::Migration[6.0]
  def up
    add_column :work_statistics, :transcribed_percentage, :integer

    WorkStatistic.find_each do |work_statistic|
      work_statistic.update(transcribed_percentage: work_statistic.pct_semi_transcribed.round)
    end
  end

  def down
    remove_column :work_statistics, :transcribed_percentage
  end
end
