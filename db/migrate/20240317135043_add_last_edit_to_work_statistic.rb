class AddLastEditToWorkStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :work_statistics, :last_edit_at, :datetime

    # Loop over every work and update last_edit_at from the maximum of the page updated_at
    Work.all.each do |work|
      last_edit_at = work.pages.maximum(:updated_at)
      work.work_statistic.update(last_edit_at: last_edit_at)
    end
  end
end
