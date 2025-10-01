class ExternalApiRequestsController < ApplicationController
  before_action :set_external_api_request, only: [:show, :edit, :update, :destroy]

  # GET /external_api_requests
  def index
    @external_api_requests = ExternalApiRequest.all
  end

  # GET /external_api_requests/1
  def show
  end

  # GET /external_api_requests/new
  def new
    @external_api_request = ExternalApiRequest.new
  end

  # GET /external_api_requests/1/edit
  def edit
  end

  # POST /external_api_requests
  def create
    @external_api_request = ExternalApiRequest.new(external_api_request_params)

    if @external_api_request.save
      redirect_to @external_api_request, notice: 'External api request was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /external_api_requests/1
  def update
    if @external_api_request.update(external_api_request_params)
      redirect_to @external_api_request, notice: 'External api request was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /external_api_requests/1
  def destroy
    @external_api_request.destroy
    redirect_to external_api_requests_url, notice: 'External api request was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_external_api_request
      @external_api_request = ExternalApiRequest.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def external_api_request_params
      params.require(:external_api_request).permit(:user_id, :collection_id, :work_id, :page_id, :engine, :status, :params)
    end
end
