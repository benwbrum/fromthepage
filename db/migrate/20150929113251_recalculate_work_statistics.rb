class RecalculateWorkStatistics < ActiveRecord::Migration[5.2]
  def change
    Work.all.each { |w| w.work_statistic.recalculate }
  end
end
