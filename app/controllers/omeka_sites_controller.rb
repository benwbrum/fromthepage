class OmekaSitesController < ApplicationController

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create, :edit, :update]

  # GET /omeka_sites
  # GET /omeka_sites.json
  def index
    @omeka_sites = current_user.omeka_sites

    respond_to do |format|
      format.html { redirect_to :controller => 'dashboard', :action => 'omeka' }
      format.json { render json: @omeka_sites }
    end
  end

  # GET /omeka_sites/items
  def items
    @omeka_site = OmekaSite.find(params[:omeka_site_id])
    if params[:omeka_col_id].present?
      @omeka_items = @omeka_site.client.get_collection(params[:omeka_col_id]).items
    else
      @omeka_items = @omeka_site.client.get_all_items().reject { |i| i.data.collection != nil }
    end

    @imported_items = OmekaItem.where(omeka_collection_id: params[:omeka_col_id]).map { |item| item.omeka_id }

    render partial: 'items.html', locals: { omeka_items: @omeka_items, imported_items: @imported_items }
  end

  # GET /omeka_sites/1
  # GET /omeka_sites/1.json
  def show
    @omeka_site = OmekaSite.find(params[:id])
    @omeka_collections = @omeka_site.client.get_all_collections()
    @omeka_collectionless_items = @omeka_site.client.get_all_items().reject { |i| i.data.collection != nil }

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
        format.html {
          flash[:notice] = "Omeka site was successfully created"
          ajax_redirect_to @omeka_site
        }
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
        format.html {
          flash[:notice] = "Omeka site was successfully updated"
          ajax_redirect_to @omeka_site
        }
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
      format.html {
        flash[:notice] = "Omeka site was successfully deleted"
        redirect_to :back
      }
      format.json { head :no_content }
    end
  end

  def review
    
  end



end