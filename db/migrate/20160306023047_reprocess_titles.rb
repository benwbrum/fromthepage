class ReprocessTitles < ActiveRecord::Migration[5.2]
  def change
    Page.all.each do |page| 
      print "Migrating text page_id=#{page.id} title=#{page.title}\n"
      page.update_column(:xml_text, page.wiki_to_xml(page.source_text, Page::TEXT_TYPE::TRANSCRIPTION)) 
    end

    Page.all.each do |page| 
      print "Migrating translation page_id=#{page.id} title=#{page.title}\n"
      page.update_column(:xml_translation, page.wiki_to_xml(page.source_translation, Page::TEXT_TYPE::TRANSLATION)) 
    end

  end
end
