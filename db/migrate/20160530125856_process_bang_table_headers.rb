class ProcessBangTableHeaders < ActiveRecord::Migration
  def change
    Page.where("id in (select page_id from table_cells)").each do |page|
      page.update_column(:xml_text, page.wiki_to_xml(page.source_text, Page::TEXT_TYPE::TRANSCRIPTION)) 
      page.update_sections_and_tables
    end
  end
end
