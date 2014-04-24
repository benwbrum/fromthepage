class Deed < ActiveRecord::Base
  # constants
  PAGE_TRANSCRIPTION = 'page_trans'
  PAGE_EDIT = 'page_edit'
  PAGE_INDEXED = 'page_index'
  ARTICLE_EDIT = 'art_edit'
  NOTE_ADDED = 'note_add'

  SHORT_PARTIALS = 
    { PAGE_TRANSCRIPTION => 'deed/page_transcription_short.html.erb', 
      PAGE_EDIT => 'deed/page_edit_short.html.erb',
      PAGE_INDEXED => 'deed/page_indexed_short.html.erb',
      ARTICLE_EDIT => 'deed/article_edit_short.html.erb',
      NOTE_ADDED => 'deed/note_added_short.html.erb' }

  LONG_PARTIALS = 
    { NOTE_ADDED => 'deed/note_added_long.html.erb' }

  # associations
  belongs_to :article
  belongs_to :collection
  belongs_to :note
  belongs_to :page
  belongs_to :user
  belongs_to :work

  validates_inclusion_of :deed_type, :in => [ PAGE_TRANSCRIPTION, PAGE_EDIT, PAGE_INDEXED, ARTICLE_EDIT, NOTE_ADDED ]

  # tested
  def short_partial
    SHORT_PARTIALS[self.deed_type]
  end

  # tested
  def long_partial
    LONG_PARTIALS[self.deed_type] || SHORT_PARTIALS[self.deed_type]
  end
end
