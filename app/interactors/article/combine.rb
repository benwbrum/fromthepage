class Article::Combine < ApplicationInteractor

  include Article::Lib::Common

  def initialize(article:, from_article_ids:)
    @article          = article
    @from_article_ids = from_article_ids

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

    rename_article(from_article, old_from_title, to_article.title)
    from_article.source_article_links.destroy_all

    Deed.where(article_id: from_article.id).update_all(article_id: to_article.id)

    if from_article.source_text
      to_article.source_text ||= ''
      to_article.source_text += from_article.source_text
    end

    to_article.save!
    from_article.destroy
  end

end
