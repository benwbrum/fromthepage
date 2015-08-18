class AddTextTypeToPageArticleLinks < ActiveRecord::Migration
  def change
    
    PageArticleLink.reset_column_information
    add_column :page_article_links, :text_type, :string, :length => 15, :default => Page::TEXT_TYPE::TRANSCRIPTION unless PageArticleLink.column_names.include?('text_type')
  end
end
