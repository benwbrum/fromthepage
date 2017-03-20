class WorkStatistic < ActiveRecord::Base
  belongs_to :work

  def pct_transcribed
      raw = self[:transcribed_pages].to_f / self[:total_pages] * 100
      raw = 0 if raw.nan?
      [[0, raw].max, 100].min
  end

  def pct_corrected
    raw = self[:corrected_pages].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_translated
      raw = self[:translated_pages].to_f / self[:total_pages] * 100
      raw = 0 if raw.nan?
      [[0, raw].max, 100].min
  end

  def pct_annotated
    raw = self[:annotated_pages].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_translation_annotated
    raw = self[:translated_annotated].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_needs_review
    raw = self[:needs_review].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_translation_needs_review
    raw = self[:translated_review].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_blank
    raw = self[:blank_pages].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_translation_blank
    raw = self[:translated_blank].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_completed
    if self.work.ocr_correction
      pct_corrected + pct_blank + pct_annotated
    else
      pct_transcribed + pct_blank + pct_annotated
    end
  end

  def pct_translation_completed
    pct_translated + pct_translation_blank + pct_translation_annotated
  end

  def recalculate
    self[:total_pages] = work.pages.count
    self[:transcribed_pages] = work.pages.where("status = '#{Page::STATUS_TRANSCRIBED}'").count 
    self[:annotated_pages] = work.pages.where("status = '#{Page::STATUS_INDEXED}'").count
    self[:blank_pages] = work.pages.where("status = '#{Page::STATUS_BLANK}'").count
    self[:corrected_pages] = work.pages.where("status = '#{Page::STATUS_TRANSCRIBED}'").count unless !self.work.ocr_correction
    self[:needs_review] = work.pages.where("status = '#{Page::STATUS_NEEDS_REVIEW}'").count
    self[:translated_pages] = work.pages.where("translation_status = '#{Page::STATUS_TRANSLATED}'").count
    self[:translated_blank] = work.pages.where("translation_status = '#{Page::STATUS_BLANK}'").count
    self[:translated_review] = work.pages.where("translation_status = '#{Page::STATUS_NEEDS_REVIEW}'").count
    self[:translated_annotated] = work.pages.where("translation_status = '#{Page::STATUS_INDEXED}'").count

    save!
  end

end
