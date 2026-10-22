class AddIndicesForReadAllWorksPerformance < ActiveRecord::Migration[7.2]
  def change
    add_index :pages, [:work_id, :position]
    add_index :page_article_links, [:article_id, :page_id]
  end
end
