class CreateArticleVersions < ActiveRecord::Migration
  def self.up
    create_table :article_versions do |t|
      # state of the page at this version
      t.column :title, :string, :limit => 255
      t.column :source_text, :text
      t.column :xml_text, :text

      # foreign keys
      t.column :user_id, :integer
      t.column :article_id, :integer

      # work version info is filled by work.transciption_version
      t.column :version, :integer, :default => 0

      # automated stuff
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :article_versions
  end
end
