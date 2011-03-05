class Deed < ActiveRecord::Base
  # constants
  PAGE_TRANSCRIPTION = 'page_trans'
  PAGE_EDIT = 'page_edit'
  PAGE_INDEXED = 'page_index'
  ARTICLE_EDIT = 'art_edit'
  NOTE_ADDED = 'note_add'
  

  SHORT_PARTIALS = 
    { PAGE_TRANSCRIPTION => 'deed/page_transcription_short.rhtml', 
      PAGE_EDIT => 'deed/page_edit_short.rhtml',
      PAGE_INDEXED => 'deed/page_indexed_short.rhtml',
      ARTICLE_EDIT => 'deed/article_edit_short.rhtml',
      NOTE_ADDED => 'deed/note_added_short.rhtml' }

  LONG_PARTIALS = 
    { NOTE_ADDED => 'deed/note_added_long.rhtml' }

  # associations
  belongs_to :article
  belongs_to :collection
  belongs_to :note
  belongs_to :page
  belongs_to :user
  belongs_to :work

  def short_partial
    SHORT_PARTIALS[self.deed_type]
  end

  def long_partial
    LONG_PARTIALS[self.deed_type] || SHORT_PARTIALS[self.deed_type]
  end
end
