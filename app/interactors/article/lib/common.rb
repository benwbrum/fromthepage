module Article::Lib::Common
  def rename_article(article, old_name, new_name)
    # walk through all pages referring to this
    article.page_article_links&.each do |link|
      page = link.page

      page.rename_article_links(old_name, new_name)
      page.save!
    end

    # walk through all articles referring to this
    article.target_article_links&.each do |link|
      source_article = link.source_article

      source_article.rename_article_links(old_name, new_name)
      source_article.save!
    end
  end
end
