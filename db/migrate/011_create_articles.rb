class CreateArticles < ActiveRecord::Migration
  def self.up
    create_table :articles do |t|
      # t.column :name, :string
      t.column :title, :string
      t.column :source_text, :text
      # automated stuff
      t.column :created_on, :datetime
      t.column :lock_version, :integer, :default => 0
    end
  end

  def self.down
    drop_table :articles
  end
end
