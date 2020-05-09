class AddUserRankBadgeCount < ActiveRecord::Migration
  def change
    add_column :users, :rank_badge_count, :integer
  end
end
