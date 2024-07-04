class AddNeedsReviewPercentageToWorkStatistics < ActiveRecord::Migration[6.0]

  def up
    add_column :work_statistics, :needs_review_percentage, :integer

    WorkStatistic.find_each do |work_statistic|
      work_statistic.update(needs_review_percentage: work_statistic.pct_needs_review.round)
    end
  end

  def down
    remove_column :work_statistics, :needs_review_percentage
  end

end
