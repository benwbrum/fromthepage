class CreateArticleArticleLinks < ActiveRecord::Migration
  def self.up
    create_table :article_article_links do |t|
      # foreign keys
      t.column :source_article_id, :integer
      t.column :target_article_id, :integer
      # text
      t.column :display_text, :string
      # automated stuff
      t.column :created_on, :datetime
    end
  end

  def self.down
    drop_table :article_article_links
  end
end
