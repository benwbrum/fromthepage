module ContributorHelper

  def single_user_contributors(collection_id, start_date, end_date, user)
    @collection ||= Collection.find_by(id: collection_id)
    condition = 'created_at >= ? AND created_at <= ?'

    deeds_scope = @collection.deeds.includes(:page, :work, :user).where(user: user)

    # Get deeds for this specific user in the time period
    @collection_deeds = deeds_scope.where(condition, start_date, end_date)

    # Get user activity time from ahoy_activity_summary
    @user_time_proportional = AhoyActivitySummary.where(
      collection_id: @collection.id,
      user_id: user.id,
      date: [start_date..end_date]
    ).sum(:minutes)

    # Set the selected user as the only active transcriber
    @active_transcribers = [user]
    @user_time_proportional = { user.id => @user_time_proportional }

    # Get breakdown of deeds by type for this user
    @recent_notes = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::NOTE_ADDED)
    @recent_transcriptions = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType.transcriptions)
    @recent_articles = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::ARTICLE_EDIT)
    @recent_translations = deeds_scope.where(condition, start_date, end_date).where(deed_type: [DeedType::PAGE_TRANSLATED, DeedType::PAGE_TRANSLATION_EDIT])
    @recent_ocr = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::OCR_CORRECTED)
    @recent_index = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::PAGE_INDEXED)
    @recent_review = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::NEEDS_REVIEW)
    @recent_xlat_index = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::TRANSLATION_INDEXED)
    @recent_xlat_review = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::TRANSLATION_REVIEW)
    @recent_work_add = deeds_scope.where(condition, start_date, end_date).where(deed_type: DeedType::WORK_ADDED)

    # For single user view, these would be empty or just the selected user
    @new_transcribers = []
    @all_collaborators = [user]
  end

  def new_contributors(collection_id, start_date, end_date)
    @collection ||= Collection.find_by(id: collection_id)
    condition = 'created_at >= ? AND created_at <= ?'

    deeds_scope = @collection.deeds.includes(:page, :work, :user)

    # Check to see if there are any deeds in the collection
    @collection_deeds = deeds_scope.where(condition, start_date, end_date)

    transcription_deeds = deeds_scope.where(
      deed_type: DeedType.transcriptions_or_corrections + DeedType.collection_joins
    )

    @recent_notes = deeds_scope.where(deed_type: DeedType::NOTE_ADDED)
    @recent_transcriptions = deeds_scope.where(deed_type: DeedType.transcriptions)
    @recent_articles = deeds_scope.where(deed_type: DeedType::ARTICLE_EDIT)
    @recent_translations = deeds_scope.where(deed_type: [DeedType::PAGE_TRANSLATED, DeedType::PAGE_TRANSLATION_EDIT])
    @recent_ocr = deeds_scope.where(deed_type: DeedType::OCR_CORRECTED)
    @recent_index = deeds_scope.where(deed_type: DeedType::PAGE_INDEXED)
    @recent_review = deeds_scope.where(deed_type: DeedType::NEEDS_REVIEW)
    @recent_xlat_index = deeds_scope.where(deed_type: DeedType::TRANSLATION_INDEXED)
    @recent_xlat_review = deeds_scope.where(deed_type: DeedType::TRANSLATION_REVIEW)
    @recent_work_add = deeds_scope.where(deed_type: DeedType::WORK_ADDED)

    # get distinct user ids per deed and create list of users
    @active_transcribers = User.joins(:deeds)
                               .where(deeds: { collection_id: @collection.id })
                               .where('deeds.created_at >= ? AND deeds.created_at <= ?', start_date, end_date)
                               .distinct

    # use ahoy activity summary to calculate ranges
    @user_time_proportional = AhoyActivitySummary.where(
      collection_id: @collection.id,
      date: [start_date..end_date]
    ).group(:user_id).sum(:minutes)

    user_active_mailers = User.active_mailers.joins(:deeds)

    # Find recent transcription deeds by user, then older deeds by user
    recent_users_ids = transcription_deeds.where(created_at: [start_date..end_date]).select(:user_id)

    older_users_ids = transcription_deeds.where(created_at: [..start_date]).select(:user_id)

    # compare older to recent list to get new transcribers
    @new_transcribers = user_active_mailers.where(id: recent_users_ids)
                                           .where.not(id: older_users_ids)

    @all_collaborators = user_active_mailers.where(id: deeds_scope.select(:user_id)).distinct
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
