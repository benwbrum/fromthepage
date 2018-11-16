module CollectionStatistic
  def work_count
    works.count
  end

  def page_count
    Page.count_by_sql("SELECT COUNT(*) FROM pages p INNER JOIN works w ON p.work_id = w.id WHERE w.collection_id = #{self.id}")
  end

  def subject_count(last_days=nil, *)
    self.articles.where("#{last_days_ago_clause(last_days, 'created_on')}").count
  end

  def mention_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM page_article_links pal INNER JOIN articles a ON pal.article_id = a.id WHERE a.collection_id = #{self.id}  #{last_days_clause(last_days, 'pal.created_on')}")
  end

  def contributor_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(DISTINCT user_id) FROM deeds WHERE collection_id = #{self.id} #{last_days_clause(last_days)}")
  end

  def comment_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::NOTE_ADDED}\" #{last_days_clause(last_days)}")
  end

  def transcription_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_TRANSCRIPTION}\" #{last_days_clause(last_days)}")
  end

  def edit_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_EDIT}\" #{last_days_clause(last_days)}")
  end

  def index_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_INDEXED}\" #{last_days_clause(last_days)}")
  end

  def translation_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_TRANSLATED}\" #{last_days_clause(last_days)}")
  end

  def ocr_count(last_days=nil, *)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::OCR_CORRECTED}\" #{last_days_clause(last_days)}")
  end

  def get_stats_hash(start_date=nil, end_date=nil)
    deeds = {
      Deed::ARTICLE_EDIT => 0,
      Deed::PAGE_TRANSCRIPTION => 0,
      Deed::PAGE_EDIT => 0,
      Deed::PAGE_INDEXED => 0,
      Deed::NOTE_ADDED => 0,
      Deed::PAGE_TRANSLATED => 0,
      Deed::PAGE_TRANSLATION_EDIT => 0,
      Deed::OCR_CORRECTED => 0,
      Deed::NEEDS_REVIEW => 0,
      Deed::TRANSLATION_REVIEW => 0,
      Deed::TRANSLATION_INDEXED => 0,
      Deed::WORK_ADDED => 0,
    }
    deeds.merge!(self.deeds.where(timeframe(start_date, end_date)).group('deed_type').count)
    
    stats = 
    {
      :works        => self.works.count,
      :pages        => self.works.joins(:pages).where(timeframe(start_date, end_date, 'pages.created_on')).count,
      :subjects     => self.articles.where(timeframe(start_date, end_date, 'created_on')).count,
      :mentions     => self.articles.joins(:page_article_links).where(timeframe(start_date, end_date, 'page_article_links.created_on')).count,
      :contributors => self.deeds.where(timeframe(start_date, end_date)).select('user_id').distinct.count,
    }
    
    stats.merge(deeds)
  end

  def calculate_complete
    #note: need to compact mapped array so it doesn't fail on a nil value
    if works.any?
      newly_calculated_percentage = (self.works.includes(:work_statistic).map(&:completed).compact.sum)/work_count
    else
      newly_calculated_percentage = 0
    end

    if newly_completed?(newly_calculated_percentage)
      wrapup_info = UserMailer::StatisticWrapup.build(object: self)
      UserMailer.project_wrapup(wrapup_info).deliver!
      logger.info "#{self.title} is complete"
    end
    self.update(pct_completed: newly_calculated_percentage)
  end


  private

  def last_days_ago_clause(last_days, column = "created_at")
    clause = ""
    if last_days
      timeframe = last_days.days.ago
      clause = "#{column} >= '#{timeframe}'"
    end
    return clause
  end

  def last_days_clause(last_days, column = "created_at")
    clause = ""
    if last_days
      clause = " AND #{column} > DATE_ADD(CURDATE(), INTERVAL -#{last_days} DAY)"
    end
    clause
  end

  def timeframe(start_date, end_date, column='created_at')
    clause = ""
    if start_date && end_date
      clause = "#{column} BETWEEN '#{start_date.to_s(:db)}' AND '#{end_date.to_s(:db)}'"
    elsif start_date
      clause = "#{column} >= '#{start_date.to_s(:db)}'"
    elsif end_date
      clause = "#{column} <= '#{end_date.to_s(:db)}'"
    else
    end
    clause
  end

  def newly_completed?(newly_calculated_percentage)
    (newly_calculated_percentage == 100) && (newly_calculated_percentage != pct_completed)
  end
end
