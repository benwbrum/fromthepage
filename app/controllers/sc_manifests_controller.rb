class ScManifestsController < ApplicationController
  before_action :set_sc_manifest, only: [:show, :edit, :update, :destroy]

  respond_to :html

  def index
    @sc_manifests = ScManifest.all
    respond_with(@sc_manifests)
  end

  def show
    respond_with(@sc_manifest)
  end

  def new
    @sc_manifest = ScManifest.new
    respond_with(@sc_manifest)
  end

  def edit
  end

  def create
    @sc_manifest = ScManifest.new(sc_manifest_params)
    @sc_manifest.save
    respond_with(@sc_manifest)
  end

  def update
    @sc_manifest.update(sc_manifest_params)
    respond_with(@sc_manifest)
  end

  def destroy
    @sc_manifest.destroy
    respond_with(@sc_manifest)
  end


  def convert
    @sc_manifest = ScManifest.find(params[:sc_manifest_id])
    
    # suspect this is dead code. look at sc_manifest covert* 
    # with 25 minutes to demo, we'll do all the work here
    unless @sc_manifest.sc_collection.collection
      setup_collection(@sc_manifest.sc_collection)
    end
    
    work = Work.new
    work.collection = @sc_manifest.sc_collection.collection
    work.title = @sc_manifest.label
    work.owner = current_user
    work.save!
    @sc_manifest.work = work
    @sc_manifest.save!
    
    @sc_manifest.sc_canvases.each do |canvas|
      page = Page.new
      page.base_image = nil
      page.base_height = canvas.sc_canvas_height
      page.base_width = canvas.sc_canvas_width
      page.title = canvas.sc_canvas_label
      work.pages << page #necessary to make acts_as_list work here
      work.save!
      page.save!
      canvas.page = page
      canvas.save!
    end
    work.save!

    
    
    
  end



  private
   
   
    def setup_collection(sc_collection)
      collection = Collection.new
      collection.title = 'IIIF Collection'
      collection.owner = current_user
      collection.save!
      
      sc_collection.collection = collection;
      sc_collection.save!
    end
  
    def set_sc_manifest
      @sc_manifest = ScManifest.find(params[:id])
    end

    def sc_manifest_params
      params.require(:sc_manifest).permit(:work_id, :sc_collection_id, :sc_id, :label, :metadata, :first_sequence_id, :first_sequence_label)
    end
end
