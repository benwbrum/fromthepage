class AdminController < ApplicationController
  before_filter :authorized?

  def authorized?
    unless logged_in? && current_user.admin
      redirect_to :controller => 'dashboard'
    end
  end

  def edit_user
  end

  def update_user
    @user.update_attributes(params[:user])
    @user.save!
    redirect_to :action => 'edit_user', :user_id => @user.id
  end

  def delete_user
    @user.destroy
    redirect_to :controller => 'dashboard'
  end

  # display sessions for a user 
  def session_list
    if(@user)
      @user_name = @user.login
      condition = "user_id = #{@user.id} "
    else
      @user_name = 'Anonymous'
      condition = "user_id is null and browser not like '%google%' "+
        "and browser not like '%Yahoo! Slurp%' "+ 
        "and browser not like '%msnbot%' "+ 
        "and browser not like '%Twiceler%' "+ 
        "and browser not like '%Alexa Toolbar%' "+ 
        "and browser not like '%Baiduspider%' "+ 
        "and browser not like '%majestic12%' " 
    end
    sql = 'select session_id, '+
          'browser, '+
          'ip_address, '+
          'count(*) as total, '+
          'min(created_on) as started '+
          'from interactions '+
          'where ' + condition +
          'group by session_id, browser, ip_address ' +
          'order by started desc '

    limit = params[:limit] || 50
    @offset = params[:offset] || 0
    Interaction.connection.add_limit_offset!(sql, 
                                             { :limit => limit,
                                               :offset => @offset } )
    logger.debug(sql)
    @sessions = 
      Interaction.connection.select_all(sql)
      
  end
  
  
  # display last interactions, including who did what to which
  # actor, action, object, detail 
  def interaction_list
    # interactions for a session
    if(params[:session_id])
      conditions = "session_id = '#{params['session_id']}'"
    else if(@user)
        # interactions for user
        conditions = "user_id = #{@user.id}"
      else 
        # all interactions
        conditions = nil
      end
    end
    @interactions = 
      Interaction.find(:all, {:conditions => conditions , :order => 'id ASC'})
  end
  
  # display last interactions, including who did what to which
  # actor, action, object, detail 
  def error_list
    # interactions with errors
    limit = params[:limit] || 50
    @interactions = 
      Interaction.find(:all, 
                       {:conditions => "status='incomplete'", 
                        :order => 'id DESC',
                        :limit => limit})
  end
  
  def tail_logfile
    @lines = params[:lines].to_i
    development_logfile = "#{Rails.root}/log/development.log"
    production_logfile = "#{Rails.root}/log/production.log"
    @dev_tail = `tail -#{@lines} #{development_logfile}`
    @prod_tail = `tail -#{@lines} #{production_logfile}`
  end
  

end
