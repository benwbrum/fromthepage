class CleanOrphanPageLinkRecords < ActiveRecord::Migration[6.1]
  def up
    page_article_links = PageArticleLink.where(article_id: nil).or(PageArticleLink.where(page_id: nil))

    page_article_links.in_batches(of: 1000).destroy_all
  end
end
