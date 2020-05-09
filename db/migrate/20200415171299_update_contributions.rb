class UpdateContributions < ActiveRecord::Migration
  def change
    change_column :contributions, :text, :text
  end
end