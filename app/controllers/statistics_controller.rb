class StatisticsController < ApplicationController

  def collection
    @works = @collection.works
  #  @works.sort { |w1, w2| w2.work_statistic.pct_transcribed <=> w1.work_statistic.pct_transcribed }

    @users = User.all
    @all_transcribers = build_user_array(Deed::PAGE_TRANSCRIPTION)
    @all_editors      = build_user_array(Deed::PAGE_EDIT)
    @all_indexers     = build_user_array(Deed::PAGE_INDEXED)
  end

  private
  def build_user_array(deed_type)
    user_array = []
    deeds_by_user = Deed.group('user_id').where(work_id: @collection.works.ids).where(deed_type: deed_type).order('count_id desc').count('id')
    deeds_by_user.each { |user_id, count| user_array << [ @users.find { |u| u.id == user_id }, count ] }

    return user_array
  end

end