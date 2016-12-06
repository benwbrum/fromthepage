class DashboardController < ApplicationController

  include AddWorkHelper

  before_filter :authorized?, :only => [:owner, :staging, :omeka, :startproject]
  before_filter :get_data, :only => [:owner, :staging, :omeka, :upload, :new_upload, :startproject, :empty_work, :create_work]

  def authorized?
    unless user_signed_in? && current_user.owner
      redirect_to dashboard_path
    end
  end

  def dashboard_role
    if user_signed_in?
      if current_user.owner
        redirect_to dashboard_owner_path
      else
        redirect_to dashboard_watchlist_path
      end
    else
      redirect_to guest_dashboard_path
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

  #Public Dashboard
  def index
    collections = Collection.all
    @document_sets = DocumentSet.all
    @collections = (collections + @document_sets).sort{|a,b| a.title <=> b.title }
  end

  #Owner Dashboard - start project
  #other methods in AddWorkHelper
  def startproject
    @work = Work.new
    @work.collection = @collection
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

  #Owner Dashboard - list of works
  def owner
  end

  #Collaborator Dashboard - watchlist
  def watchlist
    @user = current_user
    collection_ids = Deed.where(:user_id => current_user.id).select(:collection_id).distinct.limit(5).map(&:collection_id)
    @collections = Collection.where(:id => collection_ids).order_by_recent_activity
    @page = recent_work
  end

  #Collaborator Dashboard - user with no activity watchlist
  def recent_work
    recent_deeds = Deed.where("work_id is not null AND collection_id not in (SELECT id FROM collections where restricted = 1) AND work_id not in (SELECT id FROM works where restrict_scribes = 1)").order('created_at desc').limit(10)
    @works = []
    #iterate through recent deeds to find works with blank pages
    recent_deeds.each do |d|
      recent = Work.find_by(id: d.work_id)
      if (recent != nil) && recent.pages.where("xml_text is null").any?
        @works << recent
      end
    end
    #find the first blank page in the most recently accessed work (as long as the works list isn't blank)
    unless @works.empty?
      recent_work = (Work.find_by(id: @works.first.id)).pages.where("xml_text is null").first
    #if the works list is blank, return nil
    else
      recent_work = nil
    end
  end


  #Collaborator Dashboard - activity
  def editor
    @user = current_user
  end

  #Guest Dashboard - activity
  def guest
    @collections = Collection.order_by_recent_activity.unrestricted.to_a.take(5)
  end

end
