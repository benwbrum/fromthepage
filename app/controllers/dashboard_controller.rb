class DashboardController < ApplicationController

  before_filter :authorized?, :only => [:owner, :staging]
  before_filter :get_data, :only => [:owner, :staging]

  def authorized?
    unless user_signed_in? && current_user.owner
      redirect_to dashboard_path
    end
  end

  def get_data
    @collections = current_user.collections
    @image_sets = current_user.image_sets
    @notes = current_user.notes
    @works = current_user.owner_works
    @ia_works = current_user.ia_works

    logger.debug("DEBUG: #{current_user.inspect}")
  end

  # Public Dashboard
  def index
    @collections = Collection.order_by_recent_activity

    # not used
    #@offset = params[:offset] || 0
    #@recent_versions = PageVersion.where('page_versions.created_on desc').limit(20).offset(@offset).includes([:user, :page]).all
  end

  # Owner Dashboard - list of works
  def owner
  end

  # Owner Dashboard - staging area
  def staging
  end

  # Editor Dashboard - watchlist
  def watchlist
    @user = current_user
    collection_ids = Deed.where(:user_id => current_user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    @collections = Collection.where(:id => collection_ids).order_by_recent_activity

    # If user has no activity yet, show first 5 collections
    if @collections.empty?
      @collections = Collection.limit(5)
    end
  end

  # Editor Dashboard - activity
  def editor
    @user = current_user
  end

end