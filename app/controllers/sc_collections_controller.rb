require 'contentdm_translator'
class ScCollectionsController < ApplicationController
  before_action :set_sc_collection, only: [:show, :edit, :update, :destroy, :explore_manifest, :import_manifest]

  respond_to :html

  def index
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
    respond_with(@sc_collections)
  end

  def import_cdm
    cdm_url = params[:cdm_url]
    begin
      at_id = ContentdmTranslator.cdm_url_to_iiif(cdm_url)
      flash[:notice] = "Using CONTENTdm IIIF manifest for #{cdm_url}"
      redirect_to :action => :import, :at_id => at_id      
    rescue => e
      flash[:error] = e.message
      redirect_to :back
    end
  end

  def search_pontiiif
    search_param = params[:search_param]
    at_id = ScCollection.collection_at_id_from_pontiiif_search(pontiiif_server, search_param)
    redirect_to :action => :explore_collection, :at_id => at_id
  end

  def import
    at_id = params[:at_id]
    begin
      service = find_service(at_id)

    if service["@type"] == "sc:Collection"
      @sc_collection = ScCollection.collection_for_at_id(at_id)
      @collection = set_collection
      render 'explore_collection', at_id: at_id

    elsif service["@type"] == "sc:Manifest"
      @sc_manifest = ScManifest.manifest_for_at_id(at_id)
      find_parent = @sc_manifest.service["within"]
      if find_parent.nil? || !find_parent.is_a?(Hash)
        @sc_collection = nil
      else
        parent_at_id = @sc_manifest.service["within"]["@id"]
        unless parent_at_id.nil?
          @sc_collection = ScCollection.collection_for_at_id(parent_at_id)
        else
          @sc_collection = nil
        end
      end
      #this allows jquery to recover if there is no parent collection
      if @sc_collection
        @label = @sc_collection.label
        @col = @sc_collection.collection
      else
        @label = nil
        @col = nil
      end
      render 'explore_manifest', at_id: at_id
    end
    rescue => e
      flash[:error] = "Please enter a valid IIIF manifest URL."
      redirect_to :back
    end

  end


  def explore_manifest
    at_id = params[:at_id]
    
    begin  
      @sc_manifest = ScManifest.manifest_for_at_id(at_id)
    rescue ArgumentError
      redirect_to :action => 'explore_collection', :at_id => at_id
      return    
    end  
    @collection = set_collection
    if @sc_collection
      @label = @sc_collection.label
      @col = @sc_collection.collection
    else
      @label = nil
      @col = nil
    end
  end

  def explore_collection
    at_id = params[:at_id]
    @sc_collection = ScCollection.collection_for_at_id(at_id)
    @collection = set_collection
  end


  def import_collection
    sc_collection = ScCollection.find_by(id: params[:sc_collection_id])
    collection_id = params[:collection_id]
    cdm_ocr = !params[:contentdm_ocr].blank?
    #if collection id is set to sc_collection or no collection is set,
    # create a new collection with sc_collection label
    unless collection_id == 'sc_collection'    
      collection = Collection.find_by(id: params[:collection_id])
    end

    if collection.nil?
      collection = create_collection(sc_collection, current_user)
    end

    #make sure import folder exists
    unless Dir.exist?("#{Rails.root}/public/imports")
      Dir.mkdir("#{Rails.root}/public/imports")
    end
    #create logfile for collection
    log_file = "#{Rails.root}/public/imports/#{collection.id}_iiif.log"

    #map an array of at_ids for the selected manifests
    manifest_array = params[:manifest_id].keys.map {|id| id}
    #get a list of the manifests to pass to the rake task
    manifest_ids = manifest_array.join(" ")
    #kick off the rake task here, then redirect to the collection
    rake_call = "#{RAKE} fromthepage:import_iiif_collection[#{sc_collection.id},'#{manifest_ids}',#{collection.id},#{current_user.id},#{cdm_ocr}] --trace >> #{log_file} &"
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
    sc_collection.update_column(:collection_id, collection.id)
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
    if ContentdmTranslator.iiif_manifest_is_cdm? at_id
      ocr = !params[:contentdm_ocr].blank?
      #make sure import folder exists
      unless Dir.exist?("#{Rails.root}/public/imports")
        Dir.mkdir("#{Rails.root}/public/imports")
      end

      log_file = "#{Rails.root}/public/imports/work_#{work.id}_cdm.log"
      rake_call = "#{RAKE} fromthepage:cdm_work_update[#{work.id},#{ocr}] --trace >> #{log_file} 2>&1 &"
      logger.info rake_call
      system(rake_call)
      #flash notice about the rake task
      flash[:notice] = "Metadata #{ocr ? 'and OCR text ' : ''} is being imported from CONTENTdm and should appear shortly."
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

    def set_collection
      #used to add new collections to select box on import
      if session[:iiif_collection]
        @collection = Collection.find_by(id: session[:iiif_collection])
        session[:iiif_collection]=nil
        return @collection
      end
    end

    def find_service(at_id)
      connection = open(at_id)
      manifest_json = connection.read
      service = IIIF::Service.parse(manifest_json)
      return service
    end
    
end
