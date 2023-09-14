module ContributorHelper

  def new_contributors(collection_id, start_date, end_date)
    unless @collection
      @collection = Collection.find_by(id: collection_id)
    end
    condition = "created_at >= ? AND created_at <= ?"

    #get the start and end date params from date picker, if none, set defaults
    start_date = start_date
    end_date = end_date

    #check to see if there are any deeds in the collection
    @collection_deeds = @collection.deeds.where(condition, start_date, end_date).includes(:page, :work, :user)

    transcription_deeds = @collection.deeds.where(deed_type: DeedType.transcriptions_or_corrections).or(@collection.deeds.where(deed_type: DeedType.collection_joins))

    @recent_notes = @collection_deeds.where(deed_type: DeedType::NOTE_ADDED)
    @recent_transcriptions = @collection_deeds.where(deed_type: DeedType.transcriptions)
    @recent_articles = @collection_deeds.where(deed_type: DeedType::ARTICLE_EDIT)
    @recent_translations = @collection_deeds.where(deed_type: [DeedType::PAGE_TRANSLATED, DeedType::PAGE_TRANSLATION_EDIT])
    @recent_ocr = @collection_deeds.where(deed_type: DeedType::OCR_CORRECTED)
    @recent_index = @collection_deeds.where(deed_type: DeedType::PAGE_INDEXED)
    @recent_review = @collection_deeds.where(deed_type: DeedType::NEEDS_REVIEW)
    @recent_xlat_index = @collection_deeds.where(deed_type: DeedType::TRANSLATION_INDEXED)
    @recent_xlat_review = @collection_deeds.where(deed_type: DeedType::TRANSLATION_REVIEW)
    @recent_work_add = @collection_deeds.where(deed_type: DeedType::WORK_ADDED)

    #get distinct user ids per deed and create list of users
    user_deeds = @collection.deeds.where(condition, start_date, end_date).distinct.pluck(:user_id)
    @active_transcribers = User.where(id: user_deeds)

    # use ahoy activity summary to calculate ranges
    @user_time_proportional = AhoyActivitySummary.where(collection_id: @collection.id, date: [start_date..end_date]).group(:user_id).sum(:minutes)


    #find recent transcription deeds by user, then older deeds by user
    recent_trans_deeds = transcription_deeds.where(created_at: [start_date..end_date]).distinct.pluck(:user_id)
    recent_users = User.active_mailers.where(id: recent_trans_deeds)
    older_trans_deeds = transcription_deeds.where(created_at: [..start_date]).distinct.pluck(:user_id)
    older_users = User.active_mailers.where(id: older_trans_deeds)

    #compare older to recent list to get new transcribers
    @new_transcribers = recent_users - older_users

    all_transcribers = User.active_mailers.includes(:deeds).where(deeds: {collection_id: @collection.id}).distinct
    @all_collaborators = all_transcribers.map { |user| "#{user.display_name} <#{user.email}>"}.join(', ')
  end

  def owner_expirations
    @collections = Collection.all
    @owners = User.where(owner: true).order(paid_date: :desc)
  end

  def show_email_stats(hours)
    @hours = hours
    @recent_users = User.where("created_at > ?", Time.now - hours.to_i.hours)
    @recent_collections = Collection.where("created_on > ?", Time.now - hours.to_i.hours)
    @collections = Collection.all
  end

  def activity(collection, hours)
    @collection = collection
    new_works = Work.includes(:collection).where(collection_id: collection.id).where("created_on > ?", Time.now - hours.to_i.hours)
    @recent_iiif = new_works.joins(:sc_manifest)
    @recent_ia = new_works.joins(:ia_work)
    @recent_works = new_works - @recent_iiif - @recent_ia
    @uploads = DocumentUpload.where(collection_id: collection.id).where.not(status: 'finished').where("created_at > ?", Time.now - hours.to_i.hours)
    new_contributors(collection.id, (Time.now - hours.to_i.hours), Time.now)
    if @collection_deeds.present? || new_works.present?
      @col_activity = true
    else
      @col_activity = false
    end
    render 'admin/collection_activity'
  end

end