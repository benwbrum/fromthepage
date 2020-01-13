class UpdatePageStatus < ActiveRecord::Migration[5.2]
  def change
    ocr_ids = Work.where(ocr_correction: true).pluck(:id)
    #find pages with source text from non-ocr-corrected works
    pages = Page.where.not(work_id: ocr_ids).where.not(source_text: nil)
    blank = pages.where(status: 'blank')
    linked = pages.where("pages.id in (select page_id from page_article_links where text_type = 'transcription')")

    #set status to transcribed for pages that aren't marked blank or have page_article_links
    transcribed = pages - linked - blank
    transcribed.each do |t|
      t.update_columns(status: 'transcribed')
    end

    #set status to indexed if the page isn't marked blank
    indexed = linked - blank
    indexed.each do |i|
      i.update_columns(status: 'indexed')
    end
  end

end
