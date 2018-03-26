class DashboardController < ApplicationController

  include AddWorkHelper

  before_filter :authorized?, :only => [:owner, :staging, :omeka, :startproject, :summary]
  before_filter :get_data, :only => [:owner, :staging, :omeka, :upload, :new_upload, :startproject, :empty_work, :create_work, :summary]
  before_action :remove_col_id

  def authorized?
    unless user_signed_in? && current_user.owner
      redirect_to dashboard_path
    end
  end

  def dashboard_role
    if user_signed_in?
      if current_user.owner
        redirect_to dashboard_owner_path
      elsif current_user.guest?
        redirect_to guest_dashboard_path
      else
        redirect_to dashboard_watchlist_path
      end
    else
      redirect_to guest_dashboard_path
    end
  end

  def get_data
    @collections = current_user.all_owner_collections
    @notes = current_user.notes
    @works = current_user.owner_works
    @ia_works = current_user.ia_works
    @document_sets = current_user.document_sets

    logger.debug("DEBUG: #{current_user.inspect}")
  end

  #Public Dashboard - list of all collections
  def index
    unless (Collection.all.count > 1000)
      redirect_to collections_list_path
    else
      redirect_to landing_page_path
    end
  end

  def collections_list
    collections = Collection.includes(:owner).distinct
    @document_sets = DocumentSet.includes(:owner).distinct
    @collections = (collections + @document_sets).sort { |a,b| a.title <=> b.title }
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
    @sc_collections = ScCollection.all
  end

  #Owner Dashboard - list of works
  def owner
  end

  #Owner Summary Statistics - statistics for all owned collections
  def summary
    @statistics_object = current_user
    @all_collaborators = current_user.all_collaborators.map { |user| "#{user.display_name} <#{user.email}>"}.join(', ')

  end

  #Collaborator Dashboard - watchlist
  def watchlist
    works = Work.joins(:deeds).where(deeds: {user_id: current_user.id}).distinct
    collections = Collection.joins(:deeds).where(deeds: {user_id: current_user.id}).distinct.order_by_recent_activity.limit(5)
    document_sets = DocumentSet.joins(works: :deeds).where(works: {id: works.ids}).order('deeds.created_at DESC').distinct.limit(5)
    @collections = (collections + document_sets).sort{|a,b| a.title <=> b.title }.take(5)
    @page = recent_work
  end

  #Collaborator Dashboard - user with no activity watchlist
  def recent_work
    recent_deed_ids = Deed.joins(:collection, :work).merge(Collection.unrestricted).merge(Work.unrestricted)
                  .where("work_id is not null").order('created_at desc').distinct.limit(5).pluck(:work_id)
    @works = Work.joins(:pages).where(id: recent_deed_ids).where(pages: {status: nil})

#find the first blank page in the most recently accessed work (as long as the works list isn't blank)
    unless @works.empty?
      recent_work = @works.first.pages.where(status: nil).first
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
    @collections = Collection.order_by_recent_activity.unrestricted.distinct.limit(5)
  end

  def landing_page
    if params[:search]
      search_owners = User.search(params[:search])
      @search_results = Collection.search(params[:search]).unrestricted + DocumentSet.search(params[:search]).unrestricted
      search_ids = @search_results.map(&:owner_user_id) + search_owners.pluck(:id)
      @owners = User.where(id: search_ids).where.not(account_type: nil)
    else
      id_list = User.where.not(account_type: [nil, 'Trial']).pluck(:id)
      #merging on collections with those user ids filters out owners without collections
      @owners = User.joins(:collections).where(collections: {restricted: false}).where(collections: {owner_user_id: id_list}).distinct.order(:display_name)
    end

    #these are for the carousel
    @collections = @owners.map {|user| Collection.carousel.where(owner_user_id: user.id).first }.compact.sample(8)
  end

end
