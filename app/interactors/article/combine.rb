class Article::Combine < ApplicationInteractor
  def initialize(article:, from_article_ids:, user:)
    @article          = article
    @from_article_ids = from_article_ids
    @user             = user

    super
  end

  def perform
    return if @from_article_ids.blank?

    from_articles = Article.where(id: @from_article_ids)
                           .includes(:page_article_links, :target_article_links, :source_article_links)

    from_articles&.each do |from_article|
      combine_articles(from_article, @article)
    end
  end

  private

  def combine_articles(from_article, to_article)
    old_from_title = from_article.title
    from_article.title = "TO_BE_DELETED:#{old_from_title}"
    from_article.save!

    Article::RenameJob.perform_later(
      user_id: @user.id,
      article_id: from_article.id,
      old_name: old_from_title,
      new_name: to_article.title,
      new_article_id: to_article.id
    )
  end
end
