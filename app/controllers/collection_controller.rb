# handles administrative tasks for the collection object
class CollectionController < ApplicationController
  include ContributorHelper
  include AddWorkHelper

  public :render_to_string

  protect_from_forgery :except => [:set_collection_title,
                                   :set_collection_intro_block,
                                   :set_collection_footer_block]

  before_filter :authorized?, :only => [:new, :edit, :update, :delete]
  before_filter :load_settings, :only => [:edit, :update, :upload]
  before_action :set_collection, :only => [:show]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def enable_document_sets
    @collection.supports_document_sets = true
    @collection.save!
    redirect_to({ :controller => 'document_sets', :action => 'index', :collection_id => @collection.id })# { :controller => 'document_sets', :action => 'index', :collection_id => @collection.id }
  end

  def set_collection
    unless @collection
      @collection = Collection.friendly.find(params[:collection_slug])
      if request.path != collection_path(@collection)
        return redirect_to @collection, :status => :moved_permanently
      end
    end
  end    

  def load_settings

    @main_owner = @collection.owner
    @owners = [@main_owner] + @collection.owners
    @nonowners = User.order(:display_name) - @owners
    @nonowners.each { |user| user.display_name = user.login if user.display_name.empty? }
    @works_not_in_collection = current_user.owner_works - @collection.works
  end

  def show
    @users = User.all
    @top_ten_transcribers = build_user_array(Deed::PAGE_TRANSCRIPTION)
    @top_ten_editors      = build_user_array(Deed::PAGE_EDIT)
    @top_ten_indexers     = build_user_array(Deed::PAGE_INDEXED)
  end

  def owners
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    @nonowners = User.all - @owners
  end

  def add_owner
    @user.owner = true
    @user.save!
    @collection.owners << @user
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def remove_owner
    @collection.owners.delete(@user)
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def publish_collection
    @collection.restricted = false
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def restrict_collection
    @collection.restricted = true
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def delete
    @collection.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @collection = Collection.new
  end

  def edit
  end

  def update
    if @collection.update_attributes(params[:collection])
      flash[:notice] = 'Collection has been updated'
      redirect_to action: 'edit', collection_slug: @collection.slug
#      redirect_to action: 'edit', collection_slug: @collection.slug
    else
      render action: 'edit'
    end
  end

  # tested
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    @collection.owner = current_user
    if @collection.save
      flash[:notice] = 'Collection has been created'
      ajax_redirect_to({ controller: 'dashboard', action: 'startproject', collection_id: @collection.id })
    else
      render action: 'new'
    end
  end

  def add_work_to_collection
    logger.debug("DEBUG collection1=#{@collection}")
    set_collection_for_work(@collection, @work)
    logger.debug("DEBUG collection2=#{@collection}")
    #redirect_to action: 'edit', collection_slug: @collection.slug
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def remove_work_from_collection
    set_collection_for_work(nil, @work)
    #redirect_to action: 'edit', collection_slug: @collection.slug
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def new_work
    @work = Work.new
    @work.collection = @collection
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

def contributors
  #@collection = Collection.find_by(id: params[:collection_id])
  #Get the start and end date params from date picker, if none, set defaults
  start_date = params[:start_date]
  end_date = params[:end_date]
  
  if start_date == nil
    start_date = 1.week.ago
    end_date = DateTime.now.utc
  end

  start_date = start_date.to_datetime.beginning_of_day
  end_date = end_date.to_datetime.end_of_day

  @start_deed = start_date.strftime("%b %d, %Y")
  @end_deed = end_date.strftime("%b %d, %Y")

  new_contributors(@collection, start_date, end_date)
  
end

private
  def set_collection_for_work(collection, work)
    # first update the id on the work
    work.collection = collection
    work.save!
    # then update the id on the articles
    # consider moving this to the work model?
    for article in work.articles
      article.collection = collection
      article.save!
    end
  end

  def build_user_array(deed_type)
    user_array = []
    condition = "collection_id = ? AND deed_type = ?"
    deeds_by_user = Deed.group('user_id').where([condition, @collection.id, deed_type]).limit(10).order('count_id desc').count('id')
    deeds_by_user.each { |user_id, count| user_array << [ @users.find { |u| u.id == user_id }, count ] }
    return user_array
  end

end