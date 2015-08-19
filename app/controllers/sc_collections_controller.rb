class ScCollectionsController < ApplicationController
  before_action :set_sc_collection, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @sc_collections = ScCollection.all
    respond_with(@sc_collections)
  end

  def show
    respond_with(@sc_collection)
  end

  def new
    @sc_collection = ScCollection.new
    respond_with(@sc_collection)
  end

  def edit
  end

  def create
    @sc_collection = ScCollection.new(sc_collection_params)
    @sc_collection.save
    respond_with(@sc_collection)
  end

  def update
    @sc_collection.update(sc_collection_params)
    respond_with(@sc_collection)
  end

  def destroy
    @sc_collection.destroy
    respond_with(@sc_collection)
  end

  private
    def set_sc_collection
      @sc_collection = ScCollection.find(params[:id])
    end

    def sc_collection_params
      params.require(:sc_collection).permit(:collection_id, :context)
    end
end
