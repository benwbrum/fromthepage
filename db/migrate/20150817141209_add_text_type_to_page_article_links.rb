class AddTextTypeToPageArticleLinks < ActiveRecord::Migration[5.0]

  def change
    PageArticleLink.reset_column_information
    unless PageArticleLink.column_names.include?('text_type')
      add_column :page_article_links, :text_type, :string, length: 15,
        default: Page::TEXT_TYPE::TRANSCRIPTION
    end
    PageArticleLink.reset_column_information
  end

end
