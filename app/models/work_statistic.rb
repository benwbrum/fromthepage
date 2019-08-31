class WorkStatistic < ActiveRecord::Base
  belongs_to :work

  def pct_transcribed
    raw = self[:transcribed_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_corrected
    raw = self[:corrected_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translated
    raw = self[:translated_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_annotated
    raw = (self[:annotated_pages].to_f + self[:blank_pages].to_f) / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_annotated
    raw = (self[:translated_annotated].to_f + self[:translated_blank].to_f) / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_needs_review
    raw = self[:needs_review].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_needs_review
    raw = self[:translated_review].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_blank
    raw = self[:blank_pages].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_translation_blank
    raw = self[:translated_blank].to_f / self[:total_pages] * 100
    raw = 0.0 if raw.nan?
    [[0, raw].max, 100].min.round(2)
  end

  def pct_transcribed_or_blank
    (pct_blank + pct_transcribed).round(2)
  end

  def pct_translated_or_blank
    (pct_translation_blank + pct_translated).round(2)
  end

  def pct_completed
    if work.ocr_correction
      (pct_corrected + pct_annotated).round(2)
    else
      (pct_transcribed + pct_annotated).round(2)
    end
  end

  def pct_translation_completed
    (pct_translated + pct_translation_annotated).round(2)
  end

  def recalculate(_options = {})
    self[:total_pages] = work.pages.count

    transcription_stats = work.pages.group(:status).count

    self[:transcribed_pages]  = transcription_stats[Page::STATUS_TRANSCRIBED] || 0
    self[:corrected_pages]    = transcription_stats[Page::STATUS_TRANSCRIBED] || 0
    self[:blank_pages]        = transcription_stats[Page::STATUS_BLANK] || 0
    self[:annotated_pages]    = transcription_stats[Page::STATUS_INDEXED] || 0
    self[:needs_review]       = transcription_stats[Page::STATUS_NEEDS_REVIEW] || 0

    translation_stats = work.pages.group(:translation_status).count

    self[:translated_pages]     = translation_stats[Page::STATUS_TRANSLATED] || 0
    self[:translated_blank]     = translation_stats[Page::STATUS_BLANK] || 0
    self[:translated_annotated] = translation_stats[Page::STATUS_INDEXED] || 0
    self[:translated_review]    = translation_stats[Page::STATUS_NEEDS_REVIEW] || 0

    self[:complete] = pct_completed
    self[:translation_complete] = pct_translation_completed
    save!

    recalculate_parent_statistics
  end

  private

  # current logic to recalculate statistics for parent document set and parent collection
  def recalculate_parent_statistics
    # save completed information for collections/document sets
    work.collection&.calculate_complete
    unless work.document_sets.empty?
      work.document_sets.each(&:calculate_complete)
    end
  end
end
