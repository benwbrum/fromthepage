class Article::Rename < ApplicationInteractor
  def initialize(article:, old_name:, new_name:, new_article:)
    @article     = article
    @old_name    = old_name
    @new_name    = new_name
    @new_article = new_article

    super
  end

  def perform
    # walk through all pages referring to this
    @article.page_article_links&.each do |link|
      page = link.page

      page.rename_article_links(@old_name, @new_name)
      page.save!
    end

    # walk through all articles referring to this
    @article.target_article_links&.each do |link|
      source_article = link.source_article

      source_article.rename_article_links(@old_name, @new_name)
      source_article.save!
    end

    return if @new_article.nil?

    @article.source_article_links.destroy_all

    Deed.where(article_id: @article.id).update_all(article_id: @new_article.id)

    if @article.source_text
      @new_article.source_text ||= ''
      @new_article.source_text += @article.source_text
    end

    @new_article.save!
    @article.destroy
  end
end
