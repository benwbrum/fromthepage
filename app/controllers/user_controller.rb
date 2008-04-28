class UserController < ApplicationController
  def demo
    session[:demo_mode] = true;
    redirect_to :controller => 'dashboard'
  end
  
  def update
  @user.update_attributes(params[:user])
  redirect_to :action => 'profile', :user_id => @user.id
  end
  
end
