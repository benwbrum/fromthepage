class Article::Lib::Rename
  def initialize(article_id:, old_names:, new_name:, new_article_id:)
    @article_id     = article_id
    @new_article_id = new_article_id
    @old_names      = old_names
    @new_name       = new_name

    @article        = Article.find_by(id: article_id)
    @new_article    = Article.find_by(id: new_article_id)
  end

  def call
    # walk through all pages referring to this
    page_article_links.each do |link|
      page = link.page

      @old_names.each do |old_name|
        page.rename_article_links(old_name, @new_name)
      end
      page.save!
    end

    # walk through all articles referring to this
    target_article_links.each do |link|
      source_article = link.source_article

      @old_names.each do |old_name|
        source_article.rename_article_links(old_name, @new_name)
      end
      source_article.save!
    end

    if @article.nil?
      page_article_links.destroy_all
      target_article_links.destroy_all
      source_article_links.destroy_all

      return
    end

    return if @new_article.nil?

    source_article_links.destroy_all

    return unless @article&.persisted? && @new_article&.persisted?

    Deed.where(article_id: @article.id).update_all(article_id: @new_article.id)

    if @article.source_text
      @new_article.source_text ||= ''
      @new_article.source_text += @article.source_text
    end

    @new_article.save!
    @article.destroy
  end

  private

  def page_article_links
    @page_article_links ||= PageArticleLink.where(article_id: @article_id)
  end

  def target_article_links
    @target_article_links ||= ArticleArticleLink.where(target_article_id: @article_id)
  end

  def source_article_links
    @source_article_links ||= ArticleArticleLink.where(source_article_id: @article_id)
  end
end
