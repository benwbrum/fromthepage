module DocumentSetStatistic
  def work_count
    self.works.count
  end

  def pages
    Page.where(work_id: works.ids)
  end

  def page_count
    pages.count
  end

  def line_count
    self.works.includes(:work_statistic).sum(:line_count)
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
    Deed.where(work_id: works.ids).where(deed_type: DeedType::NOTE_ADDED).where("#{last_days_clause(last_days)}").count
  end

  def transcription_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: DeedType::PAGE_TRANSCRIPTION).where("#{last_days_clause(last_days)}").count
  end

  def edit_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: DeedType::PAGE_EDIT).where("#{last_days_clause(last_days)}").count
  end

  def index_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: DeedType::PAGE_INDEXED).where("#{last_days_clause(last_days)}").count
  end

  def translation_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: DeedType::PAGE_TRANSLATED).where("#{last_days_clause(last_days)}").count
  end

  def ocr_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: DeedType::OCR_CORRECTED).where("#{last_days_clause(last_days)}").count
  end

  def calculate_complete
   unless work_count == 0
      pct = (self.works.includes(:work_statistic).map(&:completed).sum)/work_count
    else
      pct = 0
    end
    self.update(pct_completed: pct)
  end

  def last_days_clause(last_days, column = "created_at")
    clause = ""
    if last_days
      timeframe = last_days.days.ago
      clause = "#{column} >= '#{timeframe}'"
    end
    return clause
  end

  def get_stats_hash(start_date=nil, end_date=nil)
    deeds = DeedType.generate_zero_counts_hash
    deeds.merge!(self.deeds.where(timeframe(start_date, end_date)).group('deed_type').count)

    stats =
    {
      :works                => self.works.count,
      :pages                => self.works.joins(:pages).where(timeframe(start_date, end_date, 'pages.created_on')).count,
      :subjects             => self.articles.where(timeframe(start_date, end_date, 'articles.created_on')).count,
      :mentions             => self.articles.joins(:page_article_links).where(timeframe(start_date, end_date, 'page_article_links.created_on')).count,
      :contributors         => self.deeds.where(timeframe(start_date, end_date)).select('user_id').distinct.count,
      :pages_transcribed    => self.pages.where(status: Page::COMPLETED_STATUSES).where(timeframe(start_date, end_date,'pages.edit_started_at')).count,
      :pages_incomplete     => self.pages.where(status: Page::NEEDS_WORK_STATUSES).where(timeframe(start_date, end_date, 'pages.edit_started_at')).count,
      :pages_needing_review => self.pages.where(status: :needs_review).where(timeframe(start_date, end_date, 'pages.edit_started_at')).count,
      :descriptions         => self.works.where(description_status: Work::DescriptionStatus::DESCRIBED).count,
      :line_count           => self.line_count
    }

    stats.merge(deeds)
  end
  def timeframe(start_date, end_date, column='created_at')
    timeframe_clause = ""
    if start_date && end_date
      timeframe_clause = "#{column} BETWEEN '#{start_date.to_s(:db)}' AND '#{end_date.to_s(:db)}'"
    elsif start_date
      timeframe_clause = "#{column} >= '#{start_date.to_s(:db)}'"
    elsif end_date
      timeframe_clause = "#{column} <= '#{end_date.to_s(:db)}'"
    else
    end

    timeframe_clause
  end
end
