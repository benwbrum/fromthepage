module DocumentSetStatistic
  def work_count
    self.works.count
  end

  def works
    self.works
  end

  def page_count
    Page.where(work_id: works.ids).count
  end

  def subject_count
    self.collection.articles.count
  end

  def new_subject_count(last_days)
    Article.where("collection_id = ? AND created_on >= ?", "#{self.collection.id}", "#{last_days.days.ago}").count
  end

  def mention_count(last_days=nil)
    Collection.count_by_sql("SELECT COUNT(*) FROM page_article_links pal INNER JOIN articles a ON pal.article_id = a.id WHERE a.collection_id = #{self.collection.id}  #{last_days_clause(last_days, 'pal.created_on')}")
  end

  def contributor_count(last_days=nil)
    User.joins(:deeds).where(deeds: {work_id: works.ids}).distinct.count
  end

  def comment_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'note_add').count
  end

  def transcription_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_trans').count
  end

  def edit_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_edit').count
  end

  def index_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_index').count
  end

  def translation_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'page_pg_xlat').count
  end

  def ocr_count(last_days=nil)
    Deed.where(work_id: works.ids).where(deed_type: 'ocr_corr').count
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

