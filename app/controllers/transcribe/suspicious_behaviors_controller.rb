class Transcribe::SuspiciousBehaviorsController < ApplicationController
  before_action :authenticate_user!

  def create
    collection = Collection.find(params[:collection_id])
    page = collection.pages.find(params[:page_id])

    result = SuspiciousBehaviors::Create.new(
      collection: collection,
      page: page,
      user: current_user,
      suspicious_behavior_params: suspicious_behavior_params
    ).call

    if result.success?
      render json: { response: :ok }
    else
      render json: { response: :failed }, status: :unprocessable_entity
    end
  end

  private

  def suspicious_behavior_params
    params.require(:suspicious_behavior).permit(:behavior_type, metadata: {})
  end
end
