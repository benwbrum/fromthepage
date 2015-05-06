# handles administrative tasks for the collection object
class CollectionController < ApplicationController

  public :render_to_string

  protect_from_forgery :except => [:set_collection_title,
                                   :set_collection_intro_block,
                                   :set_collection_footer_block]

  before_filter :authorized?, :only => [:edit, :delete, :new, :create]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    if !user_signed_in? || !current_user.owner
      ajax_redirect_to dashboard_path
    elsif @collection && @collection.owner != current_user
      ajax_redirect_to dashboard_path
    end
  end

  def show
    @users = User.all

    cond_string = "collection_id = ? AND deed_type = ?"
    t_deeds_by_user = Deed.group('user_id').where([cond_string, @collection.id, Deed::PAGE_TRANSCRIPTION]).limit(10).order('count_id desc').count('id')
    e_deeds_by_user = Deed.group('user_id').where([cond_string, @collection.id, Deed::PAGE_EDIT]).limit(10).order('count_id desc').count('id')
    i_deeds_by_user = Deed.group('user_id').where([cond_string, @collection.id, Deed::PAGE_INDEXED]).limit(10).order('count_id desc').count('id')

    @top_ten_transcribers = build_top_ten_array(t_deeds_by_user)
    @top_ten_editors      = build_top_ten_array(e_deeds_by_user)
    @top_ten_indexers     = build_top_ten_array(i_deeds_by_user)
  end

  def owners
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    @nonowners = User.all - @owners
  end

  def add_owner
    @collection.owners << @user
    redirect_to :action => 'owners', :collection_id => @collection.id
  end

  def remove_owner
    @collection.owners.delete(@user)
    redirect_to :action => 'owners', :collection_id => @collection.id
  end

  def publish_collection
    @collection.restricted = false
    @collection.save!
    redirect_to :action => 'owners', :collection_id => @collection.id
  end

  def restrict_collection
    @collection.restricted = true
    @collection.save!
    redirect_to :action => 'owners', :collection_id => @collection.id
  end

  def delete
    @collection.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @collection = Collection.new
  end

  def edit
    logger.debug("DEBUG collection0=#{@collection}")
    @works_not_in_collection = current_user.owner_works - @collection.works
  end

  def update
    collection = Collection.find(params[:id])
    collection.update_attributes(params[:collection])
    flash[:notice] = "Collection updated successfully."
    redirect_to :back
  end

  # tested
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    @collection.owner = current_user
    if @collection.save
      flash[:notice] = 'Collection created successfully'
      ajax_redirect_to({ :action => 'edit', :collection_id => @collection.id })
    else
      render :new
    end
  end

  def add_work_to_collection
    logger.debug("DEBUG collection1=#{@collection}")
    set_collection_for_work(@collection, @work)
    logger.debug("DEBUG collection2=#{@collection}")
    redirect_to :action => 'edit', :collection_id => @collection.id
  end

  def remove_work_from_collection
    set_collection_for_work(nil, @work)
    redirect_to :action => 'edit', :collection_id => @collection.id
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

  def build_top_ten_array(deeds_by_user)
    top_ten = []
    deeds_by_user.each { |user_id, count| top_ten << [ @users.find { |u| u.id == user_id }, count ] }
    return top_ten
  end

end