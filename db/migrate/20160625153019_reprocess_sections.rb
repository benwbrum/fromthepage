class ReprocessSections < ActiveRecord::Migration
  def change
    Section.all.each do |section|
      page = section.pages.first
      print "Migrating page id=#{page.id}, title=#{page.title}\n"
      page.update_column(:xml_text, page.wiki_to_xml(page.source_text, Page::TEXT_TYPE::TRANSCRIPTION)) 
      page.update_sections_and_tables
    end
  end
end
