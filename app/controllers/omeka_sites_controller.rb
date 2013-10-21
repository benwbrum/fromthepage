class OmekaSitesController < ApplicationController
  # GET /omeka_sites
  # GET /omeka_sites.json
  def index
    @omeka_sites = current_user.omeka_sites
    
    respond_to do |format|
      if @omeka_sites.size == 0
        format.html { redirect_to new_omeka_site_path }
      else
        format.html # index.html.erb
        
      end
      format.json { render json: @omeka_sites }
    end
  end

  # GET /omeka_sites/1
  # GET /omeka_sites/1.json
  def show
    @omeka_site = OmekaSite.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @omeka_site }
    end
  end

  # GET /omeka_sites/new
  # GET /omeka_sites/new.json
  def new
    @omeka_site = OmekaSite.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @omeka_site }
    end
  end

  # GET /omeka_sites/1/edit
  def edit
    @omeka_site = OmekaSite.find(params[:id])
  end

  # POST /omeka_sites
  # POST /omeka_sites.json
  def create
    @omeka_site = OmekaSite.new(params[:omeka_site])
    @omeka_site.user = current_user

    respond_to do |format|
      if @omeka_site.save
        format.html { redirect_to @omeka_site, notice: 'Omeka site was successfully created.' }
        format.json { render json: @omeka_site, status: :created, location: @omeka_site }
      else
        format.html { render action: "new" }
        format.json { render json: @omeka_site.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /omeka_sites/1
  # PUT /omeka_sites/1.json
  def update
    @omeka_site = OmekaSite.find(params[:id])
    @omeka_site.user = current_user

    respond_to do |format|
      if @omeka_site.update_attributes(params[:omeka_site])
        format.html { redirect_to @omeka_site, notice: 'Omeka site was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @omeka_site.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /omeka_sites/1
  # DELETE /omeka_sites/1.json
  def destroy
    @omeka_site = OmekaSite.find(params[:id])
    @omeka_site.destroy

    respond_to do |format|
      format.html { redirect_to omeka_sites_url }
      format.json { head :no_content }
    end
  end
end
