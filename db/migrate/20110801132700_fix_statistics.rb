class FixStatistics < ActiveRecord::Migration
  def self.up   
    # catch up existing works
    works = Work.find :all
    works.each do |work|
      unless work.work_statistic
        work.work_statistic = WorkStatistic.new
        work.work_statistic.recalculate
      end
    end
  end

  def self.down
  end
end
