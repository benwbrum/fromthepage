# A DeedType describes the kind of Deed a user has contributed to a page. This may
# be a transcription, translation, page edit, etc.

class DeedType
  # These constants are called individually in several parts of the app for
  # specific deed types. Their values are stored as identifiers in the deeds.deed_type
  # table field. Ex: deed.deed_type = 'page_trans' Changing these values will
  # result in broken Deed queries.
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
  COLLECTION_ACTIVE = 'coll_act'
  COLLECTION_INACTIVE = 'coll_inact'
  COLLECTION_JOINED = 'coll_join'

  # The TYPES hash houses all of the deed types and makes is easier to access
  # groups of deed types and also their human-readable names. Any new deed type
  # constant should also be added here.
  TYPES = {
    PAGE_TRANSCRIPTION => 'Page Transcribed',
    PAGE_EDIT => 'Page Edited',
    PAGE_INDEXED => 'Page Indexed',
    PAGE_MARKED_BLANK => 'Page Marked Blank',
    ARTICLE_EDIT => 'Article Edited',
    NOTE_ADDED => 'Note Added',
    PAGE_TRANSLATED => 'Page Translated',
    PAGE_TRANSLATION_EDIT => 'Translation Page Edited',
    OCR_CORRECTED => 'Page OCR Corrected',
    NEEDS_REVIEW => 'Page Needs Review',
    TRANSLATION_REVIEW => 'Translation Page Needs Review',
    TRANSLATION_INDEXED => 'Translation Page Indexed',
    WORK_ADDED => 'Work Added',
    COLLECTION_ACTIVE => 'Collection Active',
    COLLECTION_INACTIVE => 'Collection Inactive',
    COLLECTION_JOINED => 'Collection Joined'
  }

  # This `class << self` inherited group replaces the need to call `self.` on
  # all of the class methods inside. Ex: `def all_types` vs `def self.all_types`
  class << self
    def all_types
      TYPES.keys
    end

    def contributor_types
      TYPES.clone.except!(WORK_ADDED, COLLECTION_ACTIVE, COLLECTION_INACTIVE).keys
    end

    def collection_edits
      [
        PAGE_TRANSCRIPTION,
        PAGE_EDIT,
        PAGE_MARKED_BLANK,
        ARTICLE_EDIT,
        OCR_CORRECTED,
        NEEDS_REVIEW,
        TRANSLATION_REVIEW,
        COLLECTION_ACTIVE,
        COLLECTION_INACTIVE,
        COLLECTION_JOINED
      ]
    end

    def document_set_edits
      [
        PAGE_TRANSCRIPTION,
        PAGE_EDIT,
        PAGE_MARKED_BLANK,
        ARTICLE_EDIT
      ]
    end

    def transcriptions
      [
        PAGE_TRANSCRIPTION,
        PAGE_EDIT
      ]
    end

    def transcriptions_or_corrections
      [
        PAGE_TRANSCRIPTION,
        PAGE_EDIT,
        OCR_CORRECTED
      ]
    end

    def edited_and_transcribed_pages
      [
        PAGE_EDIT,
        NEEDS_REVIEW,
        OCR_CORRECTED,
        PAGE_MARKED_BLANK,
        PAGE_TRANSCRIPTION
      ]
    end

    def new_and_edited_translations
      [
        PAGE_TRANSLATION_EDIT,
        TRANSLATION_REVIEW,
        PAGE_TRANSLATED
      ]
    end

    def name(deed_type)
      TYPES[deed_type]
    end

    def generate_zero_counts_hash
      DeedType::TYPES.each_with_object({}) { |(k, v), returned_hash| returned_hash[k] = 0 }
    end
  end
end
