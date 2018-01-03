# handles administrative tasks for the collection object
class Api::CollectionController < ApplicationController
  
  before_filter :authorized?, :only => [:new, :edit, :update, :delete, :destroy, :create]
  before_action :set_collection, :only => [:show, :edit, :update, :destroy, :contributors, :new_work]
  before_filter :load_settings, :only => [:edit, :update, :upload]
  
  ### Endpoints Methods ###
  
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    @collection.owner = current_user
    if @collection.save
      
      # record activity on gamification services 
      # GamificationHelper.createCollectionEvent(current_user.email)
      
      # flash[:notice] = 'Collection has been created'
      # if request.referrer.include?('sc_collections')
        # session[:iiif_collection] = @collection.id
        # ajax_redirect_to(request.referrer)
      # else
        # ajax_redirect_to({ controller: 'dashboard', action: 'startproject', collection_id: @collection.id })
      # end
      render_serialized ResponseWS.default_ok(@collection)
    else
      # render action: 'new'
      render_serialized ResponseWS.default_error
    end
  end
  
  def update
    if params[:collection][:slug] == ""
      @collection.update(params[:collection].except(:slug))
      title = @collection.title.parameterize
      @collection.update(slug: title)
    else
      @collection.update(params[:collection])
    end
    if @collection.save!
      # flash[:notice] = 'Collection has been updated'
      # redirect_to action: 'edit', collection_id: @collection.id
      
      render_serialized ResponseWS.default_ok(@collection)
    else
      # render action: 'edit'
      render_serialized ResponseWS.default_error
    end
  end
  
  def destroy
    @collection.destroy
    # redirect_to dashboard_owner_path
    render_serialized @collection
  end
  
  def show    
    render_serialized @collection
  end
  
  def show_works
    # if @collection.restricted
    #   ajax_redirect_to dashboard_path unless user_signed_in? && @collection.show_to?(current_user)
    # end    
    @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
    render_serialized @works
  end
  
  
  ### Filter Methods ###
  
  def load_settings
    @main_owner = @collection.owner
    @owners = [@main_owner] + @collection.owners
    @nonowners = User.order(:display_name) - @owners
    @nonowners.each { |user| user.display_name = user.login if user.display_name.empty? }
    # Uncomment when token auth is ready
    # @works_not_in_collection = current_user.owner_works - @collection.works
    @collaborators = @collection.collaborators
    @noncollaborators = User.order(:display_name) - @collaborators - @collection.owners
  end
  
  # FIXME put in superclass and fix error actions
  def authorized?
    # unless user_signed_in?
    #   ajax_redirect_to dashboard_path
    # end
    # 
    # if @collection &&  !current_user.like_owner?(@collection)
    #   ajax_redirect_to dashboard_path
    # end
    
    if user_signed_in?
      puts "*** Signed in as " + current_user.login + "! ***"
    else
      puts "*** User not signed ***"
    end
  end
  
  private
    def set_collection
      unless @collection
        if Collection.friendly.exists?(params[:id])
          @collection = Collection.friendly.find(params[:id])
        elsif DocumentSet.friendly.exists?(params[:id])
          @collection = DocumentSet.friendly.find(params[:id])
        elsif !DocumentSet.find_by(slug: params[:id]).nil?
          @collection = DocumentSet.find_by(slug: params[:id])
        elsif !Collection.find_by(slug: params[:id]).nil?
          @collection = Collection.find_by(slug: params[:id])
        end
      end
    end

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
