class AddMostRecentDeedCreatedAtToWorks < ActiveRecord::Migration[6.0]
  def up
    add_column :works, :most_recent_deed_created_at, :datetime
    ids = Work.all.pluck(:id).sort

    0.upto(ids.count / 1000) do |i|
      range = ids[(i*1000)..(i*1000+1000)]
      works = Work.find(range)

      works.each do |work|
        unless work.deeds.empty?
          work.update_column(:most_recent_deed_created_at, work.deeds.first.created_at)
        else
          work.update_column(:most_recent_deed_created_at, work.created_on)
        end
        print "#{work.id} "
      end
      works = nil
      # GC.start
      print "\nend batch #{i}\n"
    end
  end

  def down
    drop_column :works, :most_recent_deed_created_at
  end
end
