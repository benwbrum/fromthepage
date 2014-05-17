class CreateWorkStatistics < ActiveRecord::Migration
  def self.up
    create_table :work_statistics do |t|
      t.integer     :work_id
      t.integer     :transcribed_pages
      t.integer     :annotated_pages
      t.integer     :total_pages
      t.timestamps
    end

    # actually process the existing works here
    works = Work.all
    works.each do |work|
      unless work.work_statistic
        work.work_statistic = WorkStatistic.new
        work.work_statistic.recalculate
      end
    end
  end

  def self.down
    drop_table :work_statistics
  end
end
