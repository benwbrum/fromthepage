module DocumentSetStatistic
  def work_count
    self.works.count
  end

  def works
    self.works
  end

  def pages
    Page.where(work_id: works.ids)
  end

  def page_count
    pages.count
  end

  def subject_count(last_days=nil)
    self.articles.where("#{last_days_clause(last_days, 'articles.created_on')}").count
  end

  def mention_count(last_days=nil)
    PageArticleLink.where(page_id: self.pages.ids).where("#{last_days_clause(last_days, 'created_on')}").count
  end

  def contributor_count(last_days=nil)
    User.joins(:deeds).where(deeds: {work_id: works.ids}).where("#{last_days_clause(last_days, 'deeds.created_at')}").distinct.count
  end

  def comment_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'note_add').where("#{last_days_clause(last_days)}").count
  end

  def transcription_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_trans').where("#{last_days_clause(last_days)}").count
  end

  def edit_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_edit').where("#{last_days_clause(last_days)}").count
  end

  def index_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_index').where("#{last_days_clause(last_days)}").count
  end

  def translation_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_pg_xlat').where("#{last_days_clause(last_days)}").count
  end

  def ocr_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'ocr_corr').where("#{last_days_clause(last_days)}").count
  end

  def pct_completed
   unless work_count == 0
      complete = self.works.where(supports_translation: false).joins(:work_statistic).sum(:complete)
      complete = complete + self.works.where(supports_translation: true).joins(:work_statistic).sum(:translation_complete)
      pct = complete/work_count
    else
      pct = 0
    end
    return pct
  end

  def last_days_clause(last_days, column = "created_at")
    clause = ""
    if last_days
      timeframe = last_days.days.ago
      clause = "#{column} >= '#{timeframe}'"
    end
    return clause
  end
end

