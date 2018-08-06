class AddVotablePublication < ActiveRecord::Migration
  def change
    add_column :publications, :cached_weighted_score, :integer, :default => 0
  end
end
