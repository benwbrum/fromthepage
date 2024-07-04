require 'csv'

class StatisticsController < ApplicationController

  def collection
    @works = @collection.works
    @stats = @collection.get_stats_hash
    @recent_stats = @collection.get_stats_hash(7.days.ago)
    #  @works.sort { |w1, w2| w2.work_statistic.pct_transcribed <=> w1.work_statistic.pct_transcribed }

    @users = User.all # Really??? TODO: fix this
    @all_transcribers = build_user_array(DeedType::PAGE_TRANSCRIPTION)
    @all_editors      = build_user_array(DeedType::PAGE_EDIT)
    @all_reviewers    = build_user_array(DeedType::PAGE_REVIEWED)
    @all_indexers     = build_user_array(DeedType::PAGE_INDEXED)
  end

  private

  def build_user_array(deed_type)
    deeds_by_user = Deed.group('user_id').where(work_id: @collection.works.ids).where(deed_type:).order('count_id desc').count('id')
    deeds_by_user.map { |user_id, count| [@users.find { |u| u.id == user_id }, count] }
  end

end
