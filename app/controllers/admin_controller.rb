class AdminController < ApplicationController
  before_filter :authorized?

  def authorized?
    logged_in? && current_user.admin
  end

  def edit_user
    @user = User.find(params[:user_id])
  end

  def update_user
    user = User.find(params[:user_id])
    user.update_attributes(params[:user])
    user.save!
    redirect_to :action => 'edit_user', :user_id => user.id
  end

  def delete_user
    user = User.find(params[:user_id])
    user.destroy
    redirect_to :controller => 'dashboard'
  end



end
