class WorkStatistic < ActiveRecord::Base
  belongs_to :work

  def pct_transcribed
    raw = self[:transcribed_pages].to_f / (self[:total_pages] - self[:blank_pages]) * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def pct_annotated
    raw = self[:annotated_pages].to_f / (self[:total_pages] - self[:blank_pages]) * 100
    raw = 0 if raw.nan?
    [[0, raw].max, 100].min
  end

  def recalculate
    self[:total_pages] = work.pages.count
    self[:transcribed_pages] = work.pages.where('source_text is not null').count 
    self[:annotated_pages] = work.pages.where('"pages.id in (select page_id from page_article_links)"').count
    self[:blank_pages] = work.pages.where("status = '#{Page::STATUS_BLANK}'").count
    self[:incomplete_pages] = work.pages.where("status = '#{Page::STATUS_INCOMPLETE}'").count
    save!
  end

end
