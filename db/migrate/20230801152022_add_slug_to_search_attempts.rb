class AddSlugToSearchAttempts < ActiveRecord::Migration[5.0]

  def change
    add_column :search_attempts, :slug, :string
    add_index :search_attempts, :slug, unique: true
  end

end
