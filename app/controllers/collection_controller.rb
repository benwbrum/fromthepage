# handles administrative tasks for the collection object
class CollectionController < ApplicationController
  public :render_to_string
  in_place_edit_for :collection, :title
  in_place_edit_for :collection, :intro_block
  in_place_edit_for :collection, :footer_block
  protect_from_forgery :except => [:set_collection_title, 
                                    :set_collection_intro_block, 
                                    :set_collection_footer_block]
  before_filter :authorized?, :only => [:edit, :delete, :new, :create]

  def authorized?
    if logged_in? && current_user.owner
      if @collection
        unless current_user.like_owner? @collection
          redirect_to :controller => 'dashboard'
        end
      end
    else
      redirect_to :controller => 'dashboard'
    end
  end

  def owners
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    @nonowners = User.find(:all) - @owners
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
    redirect_to :controller => 'dashboard'
  end

  def new
    @collection = Collection.new
  end

  def edit
    logger.debug("DEBUG collection0=#{@collection}")
    @works_not_in_collection = current_user.owner_works - @collection.works
  end

  def update
    @collection.attributes=params[:collection]
    if @collection.save
      redirect_to :action => 'show', :collection_id => @collection.id
    else
      render :action => 'edit'
    end
  end
  
  # tested
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.owner = current_user
    @collection.save!
    redirect_to :action => 'show', :collection_id => @collection.id
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
end
