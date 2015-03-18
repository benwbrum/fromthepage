class DashboardController < ApplicationController

  before_filter :authorized?, :only => [:owner, :staging]

  def authorized?
    unless user_signed_in? && current_user.owner
      redirect_to dashboard_path
    end
  end

  def index
    @collections = Collection.all

    # not used
    #@offset = params[:offset] || 0
    #@recent_versions = PageVersion.where('page_versions.created_on desc').limit(20).offset(@offset).includes([:user, :page]).all
  end

  def owner
    logger.debug("DEBUG: #{current_user.inspect}")
  end

  def staging
    @image_sets = current_user.image_sets
  end

end