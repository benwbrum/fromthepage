class RecalculateWorkStatistics < ActiveRecord::Migration
  def change
    Work.all.each { |w| w.work_statistic.recalculate }
  end
end
