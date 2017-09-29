module CollectionStatistic
  def work_count
    self.works.count
  end

  def page_count
    Collection.count_by_sql("SELECT COUNT(*) FROM pages p INNER JOIN works w ON p.work_id = w.id WHERE w.collection_id = #{self.id}")
  end

  def subject_count
    self.articles.count
  end

  def new_subject_count(last_days)
    Article.where("collection_id = ? AND created_on >= ?", "#{self.id}", "#{last_days.days.ago}").count
  end

  def mention_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM page_article_links pal INNER JOIN articles a ON pal.article_id = a.id WHERE a.collection_id = #{self.id}  #{last_days_clause(last_days, 'pal.created_on')}")
  end

  def contributor_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(DISTINCT user_id) FROM deeds WHERE collection_id = #{self.id} #{last_days_clause(last_days)}")
  end

  def comment_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::NOTE_ADDED}\" #{last_days_clause(last_days)}")
  end

  def transcription_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_TRANSCRIPTION}\" #{last_days_clause(last_days)}")
  end

  def edit_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_EDIT}\" #{last_days_clause(last_days)}")
  end

  def index_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_INDEXED}\" #{last_days_clause(last_days)}")
  end

  def translation_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::PAGE_TRANSLATED}\" #{last_days_clause(last_days)}")
  end

  def ocr_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM deeds WHERE collection_id = #{self.id} AND deed_type = \"#{Deed::OCR_CORRECTED}\" #{last_days_clause(last_days)}")
  end

  def pct_completed
    complete = 0
    unless work_count == 0
      self.works.includes(:work_statistic).each do |w|
        complete += w.work_statistic.pct_completed
      end
      pct = complete/work_count
    else
      pct = 0
    end
    return pct
  end

  def last_days_clause(last_days, column = "created_at")
    clause = ""

    if last_days
      clause = " AND #{column} > DATE_ADD(CURDATE(), INTERVAL -#{last_days} DAY)"
    end

    clause
  end
end
