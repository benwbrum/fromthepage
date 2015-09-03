class OmekaItemsController < ApplicationController

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:edit, :update]

  # GET /omeka_items
  # GET /omeka_items.json
  def index
    @omeka_items = OmekaItem.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @omeka_items }
    end
  end

  # GET /omeka_items/1
  # GET /omeka_items/1.json
  def show
    @omeka_item = OmekaItem.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @omeka_item }
    end
  end

  # GET /omeka_items/new
  # GET /omeka_items/new.json
  def new
    respond_to do |format|
      format.html do
        #redirect_to(:method => :post, :action => :create, :omeka_site_id => params[:omeka_site_id], :client_item_id => params[:client_item_id])
        create
      end
      format.json { render json: @omeka_item }
    end
  end

  # GET /omeka_items/1/edit
  def edit
    @omeka_item = OmekaItem.find(params[:id])
  end

  # POST /omeka_items
  # POST /omeka_items.json
  def create
    @omeka_site = OmekaSite.find(params[:omeka_site_id])
    client_item_id = params[:client_item_id]
    @omeka_item = OmekaItem.new_from_site_item_id(@omeka_site, client_item_id)
    @omeka_item.user = current_user

    respond_to do |format|
      if @omeka_item.save
        format.html {
          flash[:notice] = "Omeka item was successfully imported"
          redirect_to @omeka_item
        }
        format.json { render json: @omeka_item, status: :created, location: @omeka_item }
      else
        format.html { render action: 'new' }
        format.json { render json: @omeka_item.errors, status: :unprocessable_entity }
      end
    end
  end

  def import
    @omeka_item = OmekaItem.find(params[:id])
    @omeka_item.import

    respond_to do |format|
      format.html {
        flash[:notice] = "Omeka item was successfully published"
        redirect_to :controller => 'work', :action => 'edit', :work_id => @omeka_item.work.id
      }
    end
  end

  # PUT /omeka_items/1
  # PUT /omeka_items/1.json
  def update
    @omeka_item = OmekaItem.find(params[:id])

    respond_to do |format|
      if @omeka_item.update_attributes(params[:omeka_item])
        format.html {
          flash[:notice] = "Omeka item was successfully updated"
          ajax_redirect_to request.env['HTTP_REFERER'] #:back won't work here
        }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @omeka_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /omeka_items/1
  # DELETE /omeka_items/1.json
  def destroy
    @omeka_item = OmekaItem.find(params[:id])
    @omeka_item.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = "Omeka item was successfully deleted"
        redirect_to :back
      }
      format.json { head :no_content }
    end
  end

end