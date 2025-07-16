class Article::RenameJob < ApplicationJob
  queue_as :default

  def perform(article_id:, old_names:, new_name:, new_article_id: nil)
    Article::Lib::Rename.new(
      article_id: article_id, old_names: old_names.uniq, new_name: new_name, new_article_id: new_article_id
    ).call
  end
end
