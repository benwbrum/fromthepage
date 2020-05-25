class AddSlugToContributions < ActiveRecord::Migration
  def change
    add_column :contributions, :slug, :string
    add_index :contributions, :slug, unique: true
  end
end
