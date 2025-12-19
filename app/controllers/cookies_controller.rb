class CookiesController < ApplicationController
  def new
    @expand = ActiveRecord::Type::Boolean.new.cast(params[:expand])
    @privacy_preference = PrivacyPreference.new

    respond_to(&:turbo_stream)
  end

  def create
    Cookies::Create.new(
      cookies: cookies,
      privacy_preference_params: privacy_preference_params,
      user: current_user
    ).call

    respond_to(&:turbo_stream)
  end

  private

  def privacy_preference_params
    params.require(:privacy_preference).permit(:analytics, :marketing)
  end
end
