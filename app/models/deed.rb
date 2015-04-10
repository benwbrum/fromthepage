class Deed < ActiveRecord::Base

  # constants
  PAGE_TRANSCRIPTION = 'page_trans'
  PAGE_EDIT = 'page_edit'
  PAGE_INDEXED = 'page_index'
  ARTICLE_EDIT = 'art_edit'
  NOTE_ADDED = 'note_add'
  PAGE_TRANSLATED = 'pg_xlat'
  PAGE_TRANSLATION_EDIT = 'pg_xlat_ed'

  # associations
  belongs_to :article
  belongs_to :collection
  belongs_to :note
  belongs_to :page
  belongs_to :user
  belongs_to :work

  validates_inclusion_of :deed_type, :in => [ PAGE_TRANSCRIPTION, PAGE_EDIT, PAGE_INDEXED, ARTICLE_EDIT, NOTE_ADDED, PAGE_TRANSLATED, PAGE_TRANSLATION_EDIT ]

  def deed_type_name
    return case self.deed_type
    when PAGE_TRANSCRIPTION
      'Page Transcribed'
    when PAGE_EDIT
      'Page Edited'
    when PAGE_INDEXED
      'Page Indexed'
    when ARTICLE_EDIT
      'Article Edited'
    when NOTE_ADDED
      'Note Added'
    when PAGE_TRANSLATED
      'Page Translated'
    when PAGE_TRANSLATION_EDIT
      'Translation Edited'
    end
  end

end