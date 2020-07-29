class Incompatibilities20180205190722 < ActiveRecord::Migration[5.0]
  def change
    #notifications are created on user save
    unless User.all.empty?
      User.find_each(&:save)
    end
    #owner_stats is false by default - need to initalize to true for owners
    owners = User.where(owner: true)
    unless owners.empty?
      owners.each do |o|
        unless o.notification.nil?
          o.notification.owner_stats = true
          o.notification.save!
        end
      end
    end


    # from save_callbacks
    # initialize the new column before recalculations happen
    WorkStatistic.update_all(:complete => 0, :translation_complete => 0)

    # from 20170517155613_create_slugs
    Collection.find_each(&:save)
    DocumentSet.find_each(&:save)
    User.find_each(&:save)
    Work.find_each(&:save)

    # from 20171103141353_calculate_work_statistics
    #Recalculate statistics for all works
    @collection = Collection.all
    unless @collection.empty?
      @collection.each do |c|
        c.works.each do |w|
          w.work_statistic.recalculate
        end
      end
    end

    # from 20180316133826_update_collection_statistics
    Collection.all.each { |c| c.calculate_complete }
    DocumentSet.all.each {|d| d.calculate_complete}





  end
end
