class AddMostRecentDeedCreatedAtToWorks < ActiveRecord::Migration[6.0]
  def up
    add_column :works, :most_recent_deed_created_at, :datetime

    Work.includes(:deeds).each do |work|
      unless work.deeds.empty?
        work.update_column(:most_recent_deed_created_at, work.deeds.first.created_at)
      else
        work.update_column(:most_recent_deed_created_at, work.created_on)
      end
    end
  end
  def down
    drop_column :works, :most_recent_deed_created_at
  end
end
