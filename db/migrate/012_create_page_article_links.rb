class CreatePageArticleLinks < ActiveRecord::Migration
  def self.up
    create_table :page_article_links do |t|
      # foreign keys
      t.column :page_id, :integer
      t.column :article_id, :integer
      # text
      t.column :display_text, :string
      # automated stuff
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :page_article_links
  end
end
