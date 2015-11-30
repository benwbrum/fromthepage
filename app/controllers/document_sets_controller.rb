class DocumentSetsController < ApplicationController
  before_action :set_document_set, only: [:show, :edit, :update, :destroy]

  respond_to :html

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def index
    @document_sets = DocumentSet.all
    respond_with(@document_sets)
  end

  def show
    respond_with(@document_set)
  end

  def new
    @document_set = DocumentSet.new
    @document_set.collection = @collection
    respond_with(@document_set)
  end

  def edit
  end

  def create
    @document_set = DocumentSet.new(document_set_params)
    @document_set.owner = current_user
    @document_set.save!
    flash[:notice] = 'Document set has been created'
    ajax_redirect_to({ action: 'list', collection_id: @document_set.collection_id })
  end

  def assign_works
    set_work_map = params[:work_assignment]
    if set_work_map
      @collection.document_sets.each do |document_set|
        document_set.works.clear
        work_map = set_work_map[document_set.id.to_s]
        document_set.work_ids = work_map.keys.map { |id| id.to_i }
        document_set.save!
      end
    end

    redirect_to :action => :index, :collection_id => @collection.id
  end
  def update
    @document_set.update(document_set_params)
    respond_with(@document_set)
  end

  def destroy
    @document_set.destroy
    respond_with(@document_set)
  end

  private
    def set_document_set
      @document_set = DocumentSet.find(params[:id])
    end

    def document_set_params
      params.require(:document_set).permit(:is_public_boolean, :owner_user_id, :collection_id, :title, :description, :picture)
    end
end
