class UpdateTranslationStatus < ActiveRecord::Migration
def change
    pages = Page.where.not(source_translation: nil)
    blank = Page.where(status: 'blank')
    linked = pages.where("pages.id in (select page_id from page_article_links where text_type = 'translation')")

    #set status to transcribed for pages that aren't marked blank or have page_article_links
    translated = pages - linked - blank
    translated.each do |t|
      t.update_columns(translation_status: 'translated')
    end

    #set status to indexed if the page isn't marked blank
    indexed = linked - blank
    indexed.each do |i|
      i.update_columns(translation_status: 'indexed')
    end

    #set translation status to blank if status is blank
    blank.each do |b|
      b.update_columns(translation_status: 'blank')
    end

  end
end
