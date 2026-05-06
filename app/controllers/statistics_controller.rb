require 'csv'

class StatisticsController < ApplicationController
  include CollectionHelper

  def collection
    unless notes_visible?(@collection, current_user)
      flash[:error] = t('unauthorized_collection', project: @collection.title)
      redirect_to collection_path(@collection.owner, @collection)
      return
    end

    @works = @collection.works
    @stats = @collection.get_stats_hash
    @recent_stats = @collection.get_stats_hash(7.days.ago)

    @work_ids = @collection.works.ids
    relevant_deed_types = [DeedType::PAGE_TRANSCRIPTION, DeedType::PAGE_EDIT, DeedType::PAGE_REVIEWED, DeedType::PAGE_INDEXED]
    relevant_user_ids = Deed.where(work_id: @work_ids, deed_type: relevant_deed_types).distinct.pluck(:user_id).compact
    @users = User.where(id: relevant_user_ids).index_by(&:id)

    @all_transcribers = build_user_array(DeedType::PAGE_TRANSCRIPTION)
    @all_editors      = build_user_array(DeedType::PAGE_EDIT)
    @all_reviewers    = build_user_array(DeedType::PAGE_REVIEWED)
    @all_indexers     = build_user_array(DeedType::PAGE_INDEXED)
  end

  private

  def build_user_array(deed_type)
    deeds_by_user = Deed.group('user_id').where(work_id: @work_ids).where(deed_type: deed_type).order('count_id desc').count('id')
    deeds_by_user.map { |user_id, count| [@users[user_id], count] }
  end
end
