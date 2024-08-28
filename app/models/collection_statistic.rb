module CollectionStatistic
  def work_count
    self.works.count
  end

  def page_count
    Collection.count_by_sql("SELECT COUNT(*) FROM pages p INNER JOIN works w ON p.work_id = w.id WHERE w.collection_id = #{self.id}")
  end

  def line_count
    self.works.includes(:work_statistic).sum(:line_count)
  end

  def subject_count(last_days=nil)
    self.articles.where("#{timeframe_clause(last_days, 'created_on')}").count
  end

  def mention_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM page_article_links pal INNER JOIN articles a ON pal.article_id = a.id WHERE a.collection_id = #{self.id}  #{last_days_clause(last_days, 'pal.created_on')}")
  end

  def contributor_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(DISTINCT user_id) FROM deeds WHERE collection_id = #{self.id} #{last_days_clause(last_days)}")
  end

  def comment_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::NOTE_ADDED}\" #{last_days_clause(last_days)}")
  end

  def transcription_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::PAGE_TRANSCRIPTION}\" #{last_days_clause(last_days)}")
  end

  def edit_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::PAGE_EDIT}\" #{last_days_clause(last_days)}")
  end

  def index_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::PAGE_INDEXED}\" #{last_days_clause(last_days)}")
  end

  def translation_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::PAGE_TRANSLATED}\" #{last_days_clause(last_days)}")
  end

  def ocr_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{DeedType::OCR_CORRECTED}\" #{last_days_clause(last_days)}")
  end

  def activity_since(activity_since)
    self.deeds.includes(:user, :page, :work, :collection).where('created_at > ?', activity_since)
  end

  def get_stats_hash(start_date=nil, end_date=nil)
    deeds = DeedType.generate_zero_counts_hash
    deeds.merge!(self.deeds.where(timeframe(start_date, end_date)).group('deed_type').count)


    if start_date || end_date
      stats =
      {
        :works                => self.works.count,
        :pages                => self.works.joins(:pages).where(timeframe(start_date, end_date, 'pages.created_on')).count,
        :subjects             => self.articles.where(timeframe(start_date, end_date, 'created_on')).count,
        :mentions             => self.articles.joins(:page_article_links).where(timeframe(start_date, end_date, 'page_article_links.created_on')).count,
        :contributors         => self.deeds.where(timeframe(start_date, end_date)).select('user_id').distinct.count,
        :pages_transcribed    => self.pages.where(status: Page::COMPLETED_STATUSES).where(timeframe(start_date, end_date,'pages.edit_started_at')).count,
        :works_transcribed    => self.works.joins(:work_statistic).where(work_statistics: { complete: 100 }).where(timeframe(start_date, end_date, 'work_statistics.updated_at')).count,
        :pages_incomplete     => self.pages.where(status: Page::NEEDS_WORK_STATUSES).where(timeframe(start_date, end_date, 'pages.edit_started_at')).count,
        :pages_needing_review => self.pages.where(status: :needs_review).where(timeframe(start_date, end_date, 'pages.edit_started_at')).count,
        :descriptions         => self.works.where(description_status: Work::DescriptionStatus::DESCRIBED).count,
        :line_count           => self.line_count
      }
    else
      stats =
      {
        :works                => self.works.count,
        :pages                => self.works.joins(:work_statistic).sum(:total_pages),
        :subjects             => self.articles.count,
        :mentions             => self.articles.joins(:page_article_links).count,
        :contributors         => self.deeds.select('user_id').distinct.count,
        :pages_transcribed    => self.pages.where(status: Page::COMPLETED_STATUSES).count,
        :works_transcribed    => self.works.joins(:work_statistic).where(work_statistics: { complete: 100 }).count,
        :pages_incomplete     => self.pages.where(status: Page::NEEDS_WORK_STATUSES).count,
        :pages_needing_review => self.works.joins(:work_statistic).sum(:needs_review),
        :descriptions         => self.works.where(description_status: Work::DescriptionStatus::DESCRIBED).count,
        :line_count           => self.line_count
      }

    end

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

  def calculate_complete
    #note: need to compact mapped array so it doesn't fail on a nil value
    unless page_count == 0
      # Weighted by page count
      pct = (self.works.includes(:work_statistic).map{|w| w.work_statistic.pct_completed * w.work_statistic.total_pages}.compact.sum)/page_count
    else
      pct = 0
    end
    self.update(pct_completed: pct)
  end

  def timeframe_clause(last_days, column = "created_at")
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

  ##### background processing code
  def self.terminus_a_quo
    DocumentSet.maximum(:updated_at) # once we add the updated_at timestamp column to Collection, we should use the max of either
  end

  def self.update_recent_statistics
    from_time = terminus_a_quo
    work_ids = Deed.where("updated_at > ?", from_time).pluck(:work_id)
    work_ids.delete(nil)
    work_ids.sort!.uniq!
    completed_collection_ids = []
    completed_set_ids = []

    work_ids.each do |work_id|
      work = Work.where(:id => work_id).first
      if work # handle deleted works
        collection_id = work.collection_id
        unless completed_collection_ids.include? collection_id
          Collection.find(collection_id).calculate_complete # calculate the stats for this collection
          completed_collection_ids << collection_id # add to the list of collections we've dealt with
        end

        work.document_sets.each do |set|
          unless completed_set_ids.include? set.id
            set.calculate_complete
            set.touch # force update the timestamp
            completed_set_ids << set.id
          end
        end
      end
    end
  end
end
