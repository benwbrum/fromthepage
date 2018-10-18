class DeedType
  PAGE_TRANSCRIPTION = 'page_trans'
  PAGE_EDIT = 'page_edit'
  PAGE_INDEXED = 'page_index'
  PAGE_MARKED_BLANK = 'markd_blnk'
  ARTICLE_EDIT = 'art_edit'
  NOTE_ADDED = 'note_add'
  PAGE_TRANSLATED = 'pg_xlat'
  PAGE_TRANSLATION_EDIT = 'pg_xlat_ed'
  OCR_CORRECTED = 'ocr_corr'
  NEEDS_REVIEW = 'review'
  TRANSLATION_REVIEW = 'xlat_rev'
  TRANSLATION_INDEXED = 'xlat_index'
  WORK_ADDED = 'work_add'

  TYPES = {
    "#{PAGE_TRANSCRIPTION}" => 'Page Transcribed',
    "#{PAGE_EDIT}" => 'Page Edited',
    "#{PAGE_INDEXED}" => 'Page Indexed',
    "#{PAGE_MARKED_BLANK}" => 'Page Marked Blank',
    "#{ARTICLE_EDIT}" => 'Article Edited',
    "#{NOTE_ADDED}" => 'Note Added',
    "#{PAGE_TRANSLATED}" => 'Page Translated',
    "#{PAGE_TRANSLATION_EDIT}" => 'Translation Page Edited',
    "#{OCR_CORRECTED}" => 'Page OCR Corrected',
    "#{NEEDS_REVIEW}" => 'Page Needs Review',
    "#{TRANSLATION_REVIEW}" => 'Translation Page Needs Review',
    "#{TRANSLATION_INDEXED}" => 'Translation Page Indexed',
    "#{WORK_ADDED}" => 'Work Added'
  }

  class << self
    def all_types
      TYPES.keys
    end

    def contributor_types
      TYPES.clone.except!(WORK_ADDED).keys
    end

    def collection_edits
      [PAGE_TRANSCRIPTION, PAGE_EDIT, PAGE_MARKED_BLANK, ARTICLE_EDIT, OCR_CORRECTED, NEEDS_REVIEW, TRANSLATION_REVIEW]
    end

    def document_set_edits
      [PAGE_TRANSCRIPTION, PAGE_EDIT, PAGE_MARKED_BLANK, ARTICLE_EDIT]
    end

    def name(deed_type)
      TYPES[deed_type]
    end
  end
end
