class Article::RenameJob < ApplicationJob
  queue_as :default

  def perform(article_id:, old_name:, new_name:, new_article_id: nil)
    article = Article.find(article_id)
    new_article = Article.find_by(id: new_article_id)

    Article::Rename.new(article: article, old_name: old_name, new_name: new_name, new_article: new_article).call
  end
end
