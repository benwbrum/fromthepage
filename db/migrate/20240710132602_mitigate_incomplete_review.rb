class MitigateIncompleteReview < ActiveRecord::Migration[6.1]
  def change
    print "#{Time.now}\tSearching for pages\n"
    pages_to_remediate = Page.where(status: 'incomplete').select{|page| page.page_versions.second&.status == 'review'}
    print "#{Time.now}\tRemediating #{pages_to_remediate.count} pages\n"
    pages_to_remediate.each do |page|
      if page.page_article_links.present?
        page.update_columns(status: Page.statuses[:indexed])
      else
        page.update_columns(status: Page.statuses[:transcribed])
      end
    end
  end
end
