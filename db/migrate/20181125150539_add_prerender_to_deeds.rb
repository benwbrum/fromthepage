class AddPrerenderToDeeds < ActiveRecord::Migration[5.0]
  def up
    add_column :deeds, :prerender, :string, :limit => 2047
  end
  
  def down
    remove_column :deeds, :prerender
  end
end
