module OwnerStatistic
  def work_count
    self.owner_works.count
  end

  def completed_work_count
    self.owner_works.joins(:work_statistic).where(work_statistics: {complete: 100}).count
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

  def subject_count(start_date=nil, end_date=nil)
    owner_subjects.where("#{start_clause(start_date, 'created_on')}").where("#{end_clause(end_date, 'created_on')}").count
  end

  def mention_count(start_date=nil, end_date=nil)
    PageArticleLink.where(article_id: owner_subjects.ids).where("#{start_clause(start_date, 'created_on')}").where("#{end_clause(end_date, 'created_on')}").count
  end

  def contributor_count(start_date=nil, end_date=nil)
    User.joins(:deeds).where(deeds: {collection_id: collection_ids}).where("#{start_clause(start_date, 'deeds.created_at')}").where("#{end_clause(end_date, 'deeds.created_at')}").distinct.count
  end

  def comment_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'note_add').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def transcription_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_trans').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def edit_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_edit').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def index_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_index').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def translation_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'page_pg_xlat').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def ocr_count(start_date=nil, end_date=nil)
    Deed.where(collection_id: collection_ids).where(deed_type: 'ocr_corr').where("#{start_clause(start_date)}").where("#{end_clause(end_date)}").count
  end

  def start_clause(start_date, column = "created_at")
    clause = ""
    if start_date
      clause = "#{column} >= '#{start_date}'"
    end
    return clause
  end

  def end_clause(end_date, column = "created_at")
    clause = ""
    if end_date
      clause = "#{column} <= '#{end_date}'"
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
