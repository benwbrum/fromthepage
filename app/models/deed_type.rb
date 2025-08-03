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
  PAGE_REVIEWED = "pg_revd"
  TRANSLATION_REVIEWED = 'xlat_revd'
  DESCRIBED_METADATA = 'md_desc'
  EDITED_METADATA = 'md_edit'

  COMPLETED_TYPES = [
    PAGE_MARKED_BLANK,
    PAGE_REVIEWED,
    PAGE_TRANSLATED,
    TRANSLATION_INDEXED,
    TRANSLATION_REVIEWED
  ]

  # The TYPES hash houses all of the deed types and makes is easier to access
  # groups of deed types and also their human-readable names. Any new deed type
  # constant should also be added here.
  TYPES = {
    PAGE_TRANSCRIPTION => 'deed.page_transcription',
    PAGE_EDIT => 'deed.page_edit',
    PAGE_INDEXED => 'deed.page_indexed',
    PAGE_MARKED_BLANK => 'deed.page_marked_blank',
    ARTICLE_EDIT => 'deed.article_edit',
    NOTE_ADDED => 'deed.note_added',
    PAGE_TRANSLATED => 'deed.page_translated',
    PAGE_TRANSLATION_EDIT => 'deed.page_translation_edit',
    OCR_CORRECTED => 'deed.ocr_corrected',
    NEEDS_REVIEW => 'deed.needs_review',
    TRANSLATION_REVIEW => 'deed.translation_review',
    TRANSLATION_INDEXED => 'deed.translation_indexed',
    WORK_ADDED => 'deed.work_added',
    COLLECTION_ACTIVE => 'deed.collection_active',
    COLLECTION_INACTIVE => 'deed.collection_inactive',
    COLLECTION_JOINED => 'deed.collection_joined',
    PAGE_REVIEWED => 'deed.page_reviewed',
    TRANSLATION_REVIEWED => 'deed.translation_reviewed',
    DESCRIBED_METADATA => 'deed.described_metadata',
    EDITED_METADATA => 'deed.edited_metadata'
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
        PAGE_REVIEWED,
        TRANSLATION_REVIEW,
        TRANSLATION_REVIEWED,
        COLLECTION_ACTIVE,
        COLLECTION_INACTIVE,
        COLLECTION_JOINED,
        PAGE_TRANSLATED,
        PAGE_TRANSLATION_EDIT,
        DESCRIBED_METADATA,
        EDITED_METADATA,
        WORK_ADDED
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

    def collection_joins
      [
        COLLECTION_JOINED
      ]
    end

    def transcriptions_or_corrections_no_edits
      [
        PAGE_TRANSCRIPTION,
        OCR_CORRECTED
      ]
    end

    def metadata_creation_or_edits
      [
        DESCRIBED_METADATA,
        EDITED_METADATA
      ]
    end

    def edited_and_transcribed_pages
      [
        PAGE_EDIT,
        NEEDS_REVIEW,
        PAGE_REVIEWED,
        OCR_CORRECTED,
        PAGE_MARKED_BLANK,
        PAGE_TRANSCRIPTION
      ]
    end

    def new_and_edited_translations
      [
        PAGE_TRANSLATION_EDIT,
        TRANSLATION_REVIEW,
        TRANSLATION_REVIEWED,
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
