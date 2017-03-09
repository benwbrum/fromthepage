class WorkStatistic < ActiveRecord::Base
  belongs_to :work

  def pct_transcribed
      raw = (self[:transcribed_pages].to_f - self[:needs_review].to_f) / self[:total_pages] * 100
      raw = 0 if raw.nan?
      [[0, raw].max, 100].min
  end

  def pct_annotated
    raw = self[:annotated_pages].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_corrected
    raw = (self[:corrected_pages].to_f + self[:blank_pages]) / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_needs_review
    raw = self[:needs_review].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_translated
    raw = self[:translated_pages].to_f / self[:total_pages] * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def recalculate
    self[:total_pages] = work.pages.count
    self[:transcribed_pages] = work.pages.where('source_text is not null').count 
    self[:annotated_pages] = work.pages.where("pages.id in (select page_id from page_article_links)").count
    self[:blank_pages] = work.pages.where("status = '#{Page::STATUS_BLANK}'").count
    self[:incomplete_pages] = work.pages.where("status = '#{Page::STATUS_INCOMPLETE}'").count
    self[:corrected_pages] = work.pages.where("status = '#{Page::STATUS_TRANSCRIBED}'").count unless !self.work.ocr_correction
    self[:needs_review] = work.pages.where("status = '#{Page::STATUS_NEEDS_REVIEW}'").count
    self[:translated_pages] = work.pages.where("status = '#{Page::STATUS_TRANSLATED}'").count
    save!
  end

end
