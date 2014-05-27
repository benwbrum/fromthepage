class AdminController < ApplicationController
  before_filter :authorized?

  def authorized?
    unless user_signed_in? && current_user.admin
      redirect_to dashboard_path
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
    redirect_to dashboard_path
  end

  # display sessions for a user
  # not tested
  def session_list
    sql_limit = params[:limit] || 50
    @offset = params[:offset] || 0

    if(@user)
      @user_name = @user.login
      which_where = 1
    else
      @user_name = 'Anonymous'
      which_where = 2
    end

    @sessions = Interaction.list_sessions(sql_limit, @offset, which_where)
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
    @interactions = Interaction.where(conditions).order('id ASC').all
  end

  # display last interactions, including who did what to which
  # actor, action, object, detail
  def error_list
    # interactions with errors
    limit = params[:limit] || 50
    @interactions = Interaction.where("status='incomplete'").order('id DESC').limit(limit).all
  end

  def tail_logfile
    @lines = params[:lines].to_i
    development_logfile = "#{Rails.root}/log/development.log"
    production_logfile = "#{Rails.root}/log/production.log"
    @dev_tail = `tail -#{@lines} #{development_logfile}`
    @prod_tail = `tail -#{@lines} #{production_logfile}`
  end


end
