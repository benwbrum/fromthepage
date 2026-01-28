class AddCompositeIndexToPageArticleLinks < ActiveRecord::Migration[7.2]
  def change
    # Add composite index for efficient lookup by page_id and text_type
    # This optimizes the clear_links query in Page model
    add_index :page_article_links, [:page_id, :text_type], name: 'index_page_article_links_on_page_id_and_text_type'
  end
end
