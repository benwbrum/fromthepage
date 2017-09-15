class ScCollectionsController < ApplicationController
  before_action :set_sc_collection, only: [:show, :edit, :update, :destroy, :explore_manifest, :import_manifest]

  respond_to :html

  def index
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
    respond_with(@sc_collections)
  end

  def search_pontiiif
    search_param = params[:search_param]
    at_id = ScCollection.collection_at_id_from_pontiiif_search(pontiiif_server, search_param)
    redirect_to :action => :explore, :at_id => at_id
  end

  def explore
    at_id = CGI::unescape(params[:at_id])
    @sc_collection = ScCollection.collection_for_at_id(at_id)
  end

  def import
    at_id = CGI::unescape(params[:at_id])
    if at_id.include?("manifest")
      @sc_manifest = ScManifest.manifest_for_at_id(at_id)
      render 'explore_manifest', at_id: at_id
    elsif at_id.include?("collection")
      @sc_collection = ScCollection.collection_for_at_id(at_id)
      render 'explore_collection', at_id: at_id
    end
  end

  def explore_manifest
    at_id = CGI::unescape(params[:at_id])
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
  end

  def explore_collection
    at_id = CGI::unescape(params[:at_id])
    @sc_collection = ScCollection.collection_for_at_id(at_id)
  end

  def import_manifest
    at_id = CGI::unescape(params[:at_id])
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
  end

  def import_collection
    manifest_array = params[:manifest_id].keys.map {|id| id}
    collection_id = params[:collection_id]
    collection = Collection.find_by(id: params[:collection_id])
    manifest_ids = manifest_array.join(" ")
    #kick off the rake task here, then redirect to the collection
    rake_call = "#{RAKE} fromthepage:import_iiif_collection['#{manifest_ids}',#{collection_id},#{current_user.id}]"
    logger.info rake_call
    system(rake_call)
    #flash notice about the rake task
    flash[:notice] = "IIIF collection import is processing. Reload this page in a few minutes to see imported works."

    redirect_to collection_path(collection.owner, collection)
  end

  def convert_manifest
    at_id = params[:at_id]
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
    work = nil
    if params[:use_parent_collection]
      set_sc_collection
      work = @sc_manifest.convert_with_sc_collection(current_user, @sc_collection)
    else
      unless params[:sc_manifest][:collection_id].blank?
        @collection = Collection.find params[:sc_manifest][:collection_id]
        work = @sc_manifest.convert_with_collection(current_user, @collection)              
      else
        work = @sc_manifest.convert_with_no_collection(current_user) 
      end
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
#      @sc_collection = ScCollection.find(id)
      @sc_collection = ScCollection.find_by id: id
    end

    def sc_collection_params
      params.require(:sc_collection).permit(:collection_id, :context)
    end
    
end
