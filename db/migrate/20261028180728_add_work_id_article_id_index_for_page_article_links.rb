class AddWorkIdArticleIdIndexForPageArticleLinks < ActiveRecord::Migration[7.2]
  def change
    add_index :page_article_links, [:work_id, :article_id]
    add_index :page_article_links, [:article_id, :work_id]
  end
end
