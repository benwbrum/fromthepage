require 'csv'

class StatisticsController < ApplicationController

  def collection
    @works = @collection.works
    @stats = @collection.get_stats_hash
    @recent_stats = @collection.get_stats_hash(7.days.ago)
  #  @works.sort { |w1, w2| w2.work_statistic.pct_transcribed <=> w1.work_statistic.pct_transcribed }

    @all_transcribers = build_user_array(DeedType::PAGE_TRANSCRIPTION)
    @all_editors      = build_user_array(DeedType::PAGE_EDIT)
    @all_reviewers    = build_user_array(DeedType::PAGE_REVIEWED)
    @all_indexers     = build_user_array(DeedType::PAGE_INDEXED)
  end


  private
  def build_user_array(deed_type)
    # Get user_ids and counts from deeds in a single efficient query
    deed_counts = Deed.joins(:user)
                      .where(work_id: @collection.works.ids, deed_type: deed_type)
                      .where(users: { deleted: false })
                      .group(:user_id)
                      .order('count_id desc')
                      .count('deeds.id')
    
    # Return empty array if no deeds found
    return [] if deed_counts.empty?
    
    # Only load the specific users who have deeds (much more efficient than User.all)
    user_ids = deed_counts.keys
    users_by_id = User.where(id: user_ids).index_by(&:id)
    
    # Build the result array with actual User objects and their counts
    # Filter out any nil users (in case a user was deleted between queries)
    deed_counts.filter_map { |user_id, count| 
      user = users_by_id[user_id]
      [user, count] if user
    }
  end

end
