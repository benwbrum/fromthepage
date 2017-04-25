class UserController < ApplicationController

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:update, :update_profile]

  def demo
    session[:demo_mode] = true;
    redirect_to dashboard_path
  end

  def update_profile
  end

  def update
    if @user.update_attributes(params[:user])
      #record_deed
      flash[:notice] = "User profile has been updated"
      ajax_redirect_to({ :action => 'profile', :user_id => @user.id, :anchor => '' })
    else
      render :action => 'update_profile'
    end
  end

  def profile
    @collections = @user.unrestricted_collections
    @collection_ids = @collections.map {|collection| collection.id}
    @deeds = Deed.where(collection_id: @collection_ids).order("created_at DESC").limit(10)
    @notes = @user.notes.limit(10)
    @page_versions = @user.page_versions.includes(page: :work).limit(10)
    @article_versions = @user.article_versions.limit(10).joins(:article)
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
