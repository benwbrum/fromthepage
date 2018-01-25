module OwnerStatistic

  def work_count
    self.owner_works.count
  end

  def page_count
    self.owned_page_count
  end

  def owner_subjects
   Article.where(collection_id: self.all_owner_collections.ids)
  end

  def collection_ids
    [self.all_owner_collections.ids]
  end

  def subject_count
    owner_subjects.count
  end

  def new_subject_count(last_days)
     owner_subjects.where("created_on >= ?", "#{last_days.days.ago}").count
  end

  def mention_count(last_days=nil)
    PageArticleLink.where(article_id: owner_subjects.ids).where("#{timeframe_clause(last_days)}").count
  end

  def contributor_count(last_days=nil)
    #created_on is an ambiguous reference (need to refer to deeds; isn't working)
    User.joins(:deeds).where(deeds: {collection_id: collection_ids}).where("#{last_days_clause(last_days)}").references(:deeds).distinct.count
   
  end

  def comment_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'note_add').where("#{last_days_clause(last_days)}").count
   
  end

  def transcription_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_trans').where("#{last_days_clause(last_days)}").count
  end

  def edit_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_edit').where("#{last_days_clause(last_days)}").count
  end

  def index_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_index').where("#{last_days_clause(last_days)}").count
  end

  def translation_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_pg_xlat').where("#{last_days_clause(last_days)}").count
  end

  def ocr_count(last_days=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'ocr_corr').where("#{last_days_clause(last_days)}").count
  end

  def timeframe_clause(last_days)
    clause = ""
    if last_days
      timeframe = last_days.days.ago
      clause = "created_on >= '#{timeframe}'"
    end
    return clause
  end

  def last_days_clause(last_days, column = "created_at")
    clause = ""

    if last_days
      timeframe = last_days.days.ago
      clause = "created_at >= '#{timeframe}'"
    end

    clause
  end


=begin



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

=end
end
