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

  private
    def set_sc_manifest
      @sc_manifest = ScManifest.find(params[:id])
    end

    def sc_manifest_params
      params.require(:sc_manifest).permit(:work_id, :sc_collection_id, :sc_id, :label, :metadata, :first_sequence_id, :first_sequence_label)
    end
end
