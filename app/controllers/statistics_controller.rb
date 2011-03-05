class StatisticsController < ApplicationController
  # statistics controller lists top-N contributors, works status for a collection, etc
  before_filter :load_deeds
  before_filter :load_users
  
  def index
  end
  
  def collection
    @works = @collection.works :include => 'work_statistics'
    @works.sort! { |w1, w2| w2.work_statistic.pct_transcribed <=> w1.work_statistic.pct_transcribed }
  end

  def users
    @t_all_users_and_deeds = []
    @users.each { |u| @t_all_users_and_deeds << [u, @t_deeds_by_user[u.id]] if @t_deeds_by_user[u.id]}
    @e_all_users_and_deeds = []
    @users.each { |u| @e_all_users_and_deeds << [u, @e_deeds_by_user[u.id]]  if @e_deeds_by_user[u.id]}
    @i_all_users_and_deeds = []
    @users.each { |u| @i_all_users_and_deeds << [u, @i_deeds_by_user[u.id]]  if @i_deeds_by_user[u.id]}
    @t_all_users_and_deeds.sort!{ |a,b| b[1] <=> a[1] }
    @e_all_users_and_deeds.sort!{ |a,b| b[1] <=> a[1] }
    @i_all_users_and_deeds.sort!{ |a,b| b[1] <=> a[1] }
  
  end

private
  def load_deeds
    cond_string = 'deed_type = ?'
    if @collection
      cond_string = "collection_id = #{@collection.id} AND " + cond_string
    end
    
    @t_deeds_by_user = 
      Deed.count({:group => 'user_id', 
                  :conditions => [cond_string, Deed::PAGE_TRANSCRIPTION]})
    @e_deeds_by_user = 
      Deed.count({:group => 'user_id', 
                  :conditions => [cond_string, Deed::PAGE_EDIT]})
    @i_deeds_by_user = 
      Deed.count({:group => 'user_id', 
                  :conditions => [cond_string, Deed::PAGE_INDEXED]})
  end

  def load_users
    @users = User.find :all   

    @t_users = @users.reject { |u| !@t_deeds_by_user.keys.include? u.id }
    @t_top_ten_users_and_deeds = 
      build_top_ten_array(@t_deeds_by_user)
  
    @e_top_ten_users_and_deeds = 
      build_top_ten_array(@e_deeds_by_user)
  
    @i_top_ten_users_and_deeds = 
      build_top_ten_array(@i_deeds_by_user)
  
  end

  def build_top_ten_array(deeds_by_user)
    top_ten_score = deeds_by_user.values.sort.reverse[10]
    if top_ten_score 
      top_ten_deeds = deeds_by_user.reject { |k,v| v < top_ten_score }
    else
      top_ten_deeds = deeds_by_user
    end

    top_ten_user_and_deeds = []
    
    top_ten_users = @users.reject { |u| !top_ten_deeds.keys.include? u.id }
    top_ten_users.each { |u| top_ten_user_and_deeds << [u, top_ten_deeds[u.id]] }

    return top_ten_user_and_deeds.sort!{ |a,b| b[1] <=> a[1] }
  end


end
