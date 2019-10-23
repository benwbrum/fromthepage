class RemediateSourceText < ActiveRecord::Migration[5.2]
  def change
    pages = Page.where("source_text LIKE '%</link>%'")
    pages.each do |page|
      page.update_column(:source_text, page.source_text.gsub(/\<link target_title="(..+?)">(.+?)<\/link>/, "[[\\1|\\2]]")) 
    end
  end
end
