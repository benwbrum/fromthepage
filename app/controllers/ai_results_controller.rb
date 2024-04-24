class AiResultsController < ApplicationController
  before_action :set_ai_result, only: [:show, :edit, :update, :destroy]

  # GET /ai_results
  def index
    @ai_results = AiResult.all
  end

  # GET /ai_results/1
  def show
  end

  # GET /ai_results/new
  def new
    @ai_result = AiResult.new
  end

  # GET /ai_results/1/edit
  def edit
  end

  # POST /ai_results
  def create
    @ai_result = AiResult.new(ai_result_params)

    if @ai_result.save
      redirect_to @ai_result, notice: 'Ai result was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /ai_results/1
  def update
    if @ai_result.update(ai_result_params)
      redirect_to @ai_result, notice: 'Ai result was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /ai_results/1
  def destroy
    @ai_result.destroy
    redirect_to ai_results_url, notice: 'Ai result was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_ai_result
      @ai_result = AiResult.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def ai_result_params
      params.require(:ai_result).permit(:job_type, :engine, :parameters, :status, :result, :page_id, :work_id, :collection_id, :user_id, :ai_job_id)
    end
end
