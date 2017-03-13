class RecalculateStatistics < ActiveRecord::Migration

  #Recalculate statistics for all works
  def change
    @collection = Collection.all
    unless @collection.empty?
      @collection.each do |c|
        c.works.each do |w|
          w.work_statistic.recalculate
        end
      end
    end
  end
end
