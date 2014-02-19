class UserController < ApplicationController
  def demo
    session[:demo_mode] = true;
    redirect_to dashboard_path
  end

  def update
    @user.update_attributes(params[:user])
    #record_deed
    redirect_to :action => 'profile', :user_id => @user.id
  end

  def profile
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.deed_type = Deed::NOTE_ADDED
    deed.user = current_user
    deed.save!
  end

end
