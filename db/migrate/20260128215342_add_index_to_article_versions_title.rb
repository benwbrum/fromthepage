class AddIndexToArticleVersionsTitle < ActiveRecord::Migration[7.2]
  def change
    add_index :article_versions, :title
  end
end
