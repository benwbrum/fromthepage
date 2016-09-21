module ContributorHelper

  def new_contributors(collection_id, start_date, end_date)
      @collection = Collection.find_by(id: collection_id)

      #set variables
      trans_type = ["page_trans", "page_edit"]
      note_type = "note_add"
      article_type = "art_edit"
      translate_type = ["pg_xlat", "pg_xlat_ed"]
      condition = "created_at >= ? AND created_at <= ?"

      #Get the start and end date params from date picker, if none, set defaults
      start_date = start_date
      end_date = end_date

      #find the deeds of each type in the collection
      transcription_deeds = @collection.deeds.where(deed_type: trans_type)
      note_deeds = @collection.deeds.where(deed_type: note_type)
      article_deeds = @collection.deeds.where(deed_type: article_type)
      translate_deeds = @collection.deeds.where(deed_type: translate_type)
      
      #find deeds for the date range
      @recent_notes = note_deeds.where(condition, start_date, end_date)
      @recent_transcriptions = transcription_deeds.where(condition, start_date, end_date)
      @recent_articles = article_deeds.where(condition, start_date, end_date)
      @recent_translations = translate_deeds.where(condition, start_date, end_date)

      #get distinct user ids per deed and create list of users
      user_deeds = transcription_deeds.distinct.pluck(:user_id)
      @all_transcribers = User.where(id: user_deeds)

      #find recent transcription deeds by user, then older deeds by user
      recent_trans_deeds = @recent_transcriptions.distinct.pluck(:user_id)
      recent_users = User.where(id: recent_trans_deeds)
      older_trans_deeds = transcription_deeds.where("created_at < ?", start_date).distinct.pluck(:user_id)
      older_users = User.where(id: older_trans_deeds)

      #compare older to recent list to get new transcribers
      @new_transcribers = recent_users - older_users
      
  end
end