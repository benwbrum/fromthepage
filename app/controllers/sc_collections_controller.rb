class ScCollectionsController < ApplicationController
  before_action :set_sc_collection, only: [:show, :edit, :update, :destroy, :explore_manifest, :import_manifest]

  respond_to :html

  def index
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
    respond_with(@sc_collections)
  end

  def explore
    at_id = params[:at_id]
    @sc_collection = ScCollection.collection_for_at_id(at_id)
  end

  def explore_manifest
    at_id = params[:at_id]
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
  end

  def import_manifest
    at_id = params[:at_id]
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
  end

  def convert_manifest
    at_id = params[:at_id]
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
    work = nil
    if params[:use_parent_collection]
      set_sc_collection
      work = @sc_manifest.convert_with_sc_collection(current_user, @sc_collection)
    else
      work = @sc_manifest.convert_with_collection(current_user, @collection)              
    end
    
    redirect_to :controller => 'display', :action => 'read_work', :work_id => work.id 
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
      id = params[:sc_collection_id] || params[:id]
      @sc_collection = ScCollection.find(id)
    end

    def sc_collection_params
      params.require(:sc_collection).permit(:collection_id, :context)
    end
    
end
