class DocumentSetsController < ApplicationController
  before_action :authorized?
  before_action :set_document_set, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, only: [:new, :create, :edit, :update, :transfer_form, :edit_set_collaborators, :search_collaborators]

  def authorized?
    unless user_signed_in? && @collection && current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def transfer_form
  end

  def transfer
    source_set = @collection.document_sets.where(slug: params[:source_set]).first
    target_set = @collection.document_sets.where(slug: params[:target_set]).first

    if source_set == target_set
      flash[:error] = t('.source_and_target_can_not_be_the_same')
      render :action => 'transfer_form', :layout => false
      flash.clear
    else
      if params[:status_filter] == 'all'
        works = source_set.works
      else
        works = source_set.works.joins(:work_statistic).where('work_statistics.complete' => 100)
      end

      works.each do |work|
        unless work.document_sets.include? target_set
          work.document_sets << target_set
        end
        if params[:transfer_type] == 'move'
          work.document_sets.delete(source_set)
        end
      end

      ajax_redirect_to document_sets_path(:collection_id => @collection)
    end
  end

  def index
    page = params[:page]
    page = 1 if page.blank?
    if params[:search]
      @works = @collection.search_works(params[:search]).order(:title).paginate(page: page, per_page: 20)
    else
      @works = @collection.works.order(:title).paginate(page: page, per_page: 20)
    end
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

  def edit_set_collaborators
    @collaborators = @document_set.collaborators
    @noncollaborators = User.where.not(id: @collaborators.select(:id)).order(:display_name).limit(100)
  end

  def search_collaborators
    query = "%#{params[:term].to_s.downcase}%"
    excluded_ids = @document_set.collaborators.pluck(:id) + [@document_set.owner.id]
    users = User.where('LOWER(real_name) LIKE :search OR LOWER(email) LIKE :search', search: query)
                .where.not(id: excluded_ids)
                .limit(100)

    render json: { results: users.map { |u| { text: "#{u.display_name} #{u.email}", id: u.id } } }
  end

  def create
    @document_set = DocumentSet.new(document_set_params)
    if current_user.account_type != "Staff"
      @document_set.owner = current_user
    else
      extant_collection = current_user.collections.detect { |c| c.owner.account_type != "Staff" }
      @document_set.owner = extant_collection.owner
    end
    if @document_set.save
      flash[:notice] = t('.document_created')
      ajax_redirect_to collection_settings_path(@document_set.owner, @document_set)
    else
      render action: 'new'
    end

  end

  def assign_works
    set_work_map = params.to_unsafe_hash[:work_assignment]
    set_work_map&.each_key do |work_id|
      work = @collection.works.find(work_id)
      work.document_sets.clear
      set_work_map[work_id].each_pair do |set_id, add_set|
        work.document_sets << @collection.document_sets.find(set_id) if add_set == 'true'
      end
    end

    # set next untranscribed page for each set now that works may have been added or removed
    @collection.document_sets.each(&:set_next_untranscribed_page)

    redirect_to action: :index, collection_id: @collection.id, page: params[:page]
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
    @document_set.attributes = document_set_params

    if document_set_params[:slug].blank?
      @document_set.slug = @document_set.title.parameterize
    end

    if @document_set.save
      flash[:notice] = t('.document_updated')
      unless request.referrer.include?("/settings")
        ajax_redirect_to({ action: 'index', collection_id: @document_set.collection_id })
      else
        redirect_to request.referrer
      end
    else
      settings
      render :settings
    end
  end

  def settings
    # works not yet in document set
    if params[:search]
      @works = @collection.search_collection_works(params[:search]).where.not(id: @collection.work_ids).order(:title).paginate(page: params[:page], per_page: 20)
    else
      @works = @collection.collection.works.where.not(id: @collection.work_ids).order(:title).paginate(page: params[:page], per_page: 20)
    end
    # document set edit needs the @document set variable
    @document_set ||= @collection
    @collaborators = @document_set.collaborators
  end

  def add_set_collaborator
    collaborator = User.find(params[:collaborator_id])
    @collection.collaborators << collaborator
    if collaborator.notification.add_as_collaborator && SMTP_ENABLED
      begin
        UserMailer.collection_collaborator(collaborator, @collection).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end

    redirect_to collection_edit_set_collaborators_path(@collection.owner, @collection, @document_set)
  end

  def remove_set_collaborator
    collaborator = User.find(params[:collaborator_id])
    @collection.collaborators.delete(collaborator)

    redirect_to collection_edit_set_collaborators_path(@collection.owner, @collection, @document_set)
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
