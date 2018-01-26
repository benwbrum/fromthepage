module OwnerStatistic

  def work_count
    self.owner_works.count
  end

  def page_count
    count = Page.where(work_id: self.owner_works.ids).count
  end

  def owner_subjects
   Article.where(collection_id: self.all_owner_collections.ids)
  end

  def collection_ids
    [self.all_owner_collections.ids]
  end

  def subject_count(last_days=nil)
    owner_subjects.where("#{last_days_clause(last_days, 'created_on')}").count
  end

  def mention_count(last_days=nil)
    PageArticleLink.where(article_id: owner_subjects.ids).where("#{last_days_clause(last_days, 'created_on')}").count
  end

  def contributor_count(last_days=nil)
    User.joins(:deeds).where(deeds: {collection_id: collection_ids}).where("#{last_days_clause(last_days, 'deeds.created_at')}").distinct.count
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

  def last_days_clause(last_days, column = "created_at")
    clause = ""
    if last_days
      timeframe = last_days.days.ago
      clause = "#{column} >= '#{timeframe}'"
    end
    return clause
  end

  def all_collaborators
    User.joins(:deeds).where(deeds: {collection_id: collection_ids}).distinct
  end


  #this is to prevent an error in the statistics view
  def subjects_disabled
    false
  end

end
