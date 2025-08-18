class AddWorkIdToPageArticleLinks < ActiveRecord::Migration[5.0]
  def change
    # first add a foreign key column to page_article_links to reference works
   add_reference :page_article_links, :work, null: true, foreign_key: true, index: true
    # now copy the work_id from the page to the page_article_links
    Work.all.each do |work|
      print "#{work.id} "
      PageArticleLink.where(page_id: work.pages.pluck(:id)).update_all(work_id: work.id)
    end
  end
end
