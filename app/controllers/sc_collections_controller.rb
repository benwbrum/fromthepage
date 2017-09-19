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
      parent_at_id = @sc_manifest.service["within"]["@id"]
      unless parent_at_id.nil?
        @sc_collection = ScCollection.collection_for_at_id(parent_at_id)
      else
        @sc_collection = nil
      end
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
    #map an array of at_ids for the selected manifests
    manifest_array = params[:manifest_id].keys.map {|id| id}
    sc_collection = ScCollection.find_by(id: params[:sc_collection_id])

    collection_id = params[:collection_id]
    #if collection id is set to sc_collection or no collection is set,
    # create a new collection with sc_collection label
    unless collection_id == 'sc_collection'    
      collection = Collection.find_by(id: params[:collection_id])
    end

    if collection.nil?
      collection = create_collection(sc_collection, current_user)
    end
    #get a list of the manifests to pass to the rake task
    manifest_ids = manifest_array.join(" ")
    #kick off the rake task here, then redirect to the collection
    rake_call = "#{RAKE} fromthepage:import_iiif_collection['#{manifest_ids}',#{collection.id},#{current_user.id}]"
    logger.info rake_call
    system(rake_call)
    #flash notice about the rake task
    flash[:notice] = "IIIF collection import is processing. Reload this page in a few minutes to see imported works."

    ajax_redirect_to collection_path(collection.owner, collection)
  end

  def create_collection(sc_collection, current_user)
    collection = Collection.new
    collection.owner = current_user
    collection.title = sc_collection.label.truncate(255, separator: ' ', omission: '')
    collection.save!
    return collection
  end

  def convert_manifest
    at_id = params[:at_id]
    @sc_manifest = ScManifest.manifest_for_at_id(at_id)
    work = nil
    if params[:sc_manifest][:collection_id] == 'sc_collection'
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
