=begin
This can be commented out because statistics are recalculated in a later migration
class RecalculateWorkStatistic < ActiveRecord::Migration
  def change
    #Need to trigger the recalculate method of work statistics to fix bug #517
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
=end