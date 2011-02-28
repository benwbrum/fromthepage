class WorkStatistic < ActiveRecord::Base
  belongs_to :work

  def pct_transcribed
    (self[:transcribed_pages].to_f / (self[:total_pages] - self[:blank_pages])) * 100
  end

  def pct_annotated
    (self[:annotated_pages].to_f / (self[:total_pages] - self[:blank_pages])) * 100    
  end
  
  def recalculate
    self[:total_pages] = work.pages.count
    self[:transcribed_pages] = work.pages.count :conditions => 'xml_text is not null'
    self[:annotated_pages] = work.pages.count :conditions=> "pages.id in (select page_id from page_article_links)"
    self[:blank_pages] = work.pages.count :conditions=> "status = '#{Page::STATUS_BLANK}'"
    self[:incomplete_pages] = work.pages.count :conditions=> "status = '#{Page::STATUS_INCOMPLETE}'"
    save!
  end
end
