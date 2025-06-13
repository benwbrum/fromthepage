class Article::RenameJob < ApplicationJob
  queue_as :default

  def perform(article_id:, old_name:, new_name:, new_article_id: nil)
    Article::Lib::Rename.new(
      article_id: article_id, old_name: old_name, new_name: new_name, new_article_id: new_article_id
    ).call
  end
end
