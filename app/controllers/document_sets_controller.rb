class DocumentSetsController < ApplicationController
  before_action :set_document_set, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create, :edit, :update]

  def index
    @works = @collection.works.order(:title).paginate(page: params[:page], per_page: 20)
  end

  def show
    @collection = @document_set.collection
  end

  def new
    @document_set = DocumentSet.new
    @document_set.collection = @collection
    respond_with(@document_set)
  end

  def edit
    respond_with(@document_set)
  end

  def create
    @document_set = DocumentSet.new(document_set_params)
    @document_set.owner = current_user
    if @document_set.save
      flash[:notice] = 'Document set has been created'
      ajax_redirect_to collection_settings_path(@document_set.owner, @document_set)
    else
      render action: 'new'
    end

  end

  def assign_works
    set_work_map = params[:work_assignment]
    if set_work_map
      @collection.document_sets.each do |document_set|
        #document_set.works.clear
        work_map = set_work_map[document_set.id.to_s]
        current_ids = document_set.works.pluck(:id)
        if work_map
          new_ids = work_map.keys.map { |id| id.to_i }
          set = (current_ids - new_ids + new_ids)
          document_set.work_ids = set

          document_set.save!          
        end
      end
    end

    redirect_to :action => :index, :collection_id => @collection.id
  end

  def assign_to_set
    unless @collection
      @collection = DocumentSet.friendly.find(params[:collection_id])
    end
    new_ids = params[:work].keys.map {|id| id.to_i}
    ids = @collection.work_ids + new_ids
    @collection.work_ids = ids
    @collection.save!
    redirect_to collection_works_list_path(@collection.owner, @collection)
  end

  def remove_from_set
    @collection = DocumentSet.friendly.find(params[:collection_id])
    ids = params[:work].keys.map {|id| id.to_i}
    new_ids = @collection.work_ids - ids
    @collection.work_ids = new_ids
    @collection.save!
    redirect_to collection_works_list_path(@collection.owner, @collection)
  end

  def update
    if params[:document_set][:slug] == ""
      @document_set.update(params[:document_set].except(:slug))
      title = @document_set.title.parameterize
      @document_set.update(slug: title)
    else
      @document_set.update(document_set_params)
    end

    @document_set.save!
    flash[:notice] = 'Document set has been saved'
    unless request.referrer.include?("/settings")
      ajax_redirect_to({ action: 'index', collection_id: @document_set.collection_id })
    else
      redirect_to request.referrer
    end
  end

  def settings
    #works not yet in document set
    if params[:search]
      @works = @collection.search_collection_works(params[:search]).where.not(id: @collection.work_ids).order(:title).paginate(page: params[:page], per_page: 20)
    else
      @works = @collection.collection.works.where.not(id: @collection.work_ids).order(:title).paginate(page: params[:page], per_page: 20)
    end
    #document set edit needs the @document set variable
    @document_set = @collection
    @collaborators = @document_set.collaborators
    @noncollaborators = User.order(:display_name) - @collaborators
  end

  def add_set_collaborator
    @collection.collaborators << @user
    if @user.notification.add_as_collaborator
      if SMTP_ENABLED
        begin
          UserMailer.collection_collaborator(@user, @collection).deliver!
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message}"
        end
      end
    end
    redirect_to collection_settings_path(@collection.owner, @collection)
  end

  def remove_set_collaborator
    @collection.collaborators.delete(@user)
    redirect_to collection_settings_path(@collection.owner, @collection)
  end

  def publish_set
    @collection.is_public = true
    @collection.save!
    redirect_to collection_settings_path(@collection.owner, @collection)
  end

  def restrict_set
    @collection.is_public = false
    @collection.save!
    redirect_to collection_settings_path(@collection.owner, @collection)
  end

  def destroy
    @document_set.destroy
    redirect_to action: 'index', collection_id: @document_set.collection_id

  end

  private
    def set_document_set
      unless (defined? @document_set) && @document_set
        id = params[:document_set_id] || params[:id]
        @document_set = DocumentSet.friendly.find(id)
      end
    end

    def document_set_params
      params.require(:document_set).permit(:is_public, :owner_user_id, :collection_id, :title, :description, :picture, :slug)
    end
end
