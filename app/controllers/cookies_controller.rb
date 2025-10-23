class CookiesController < ApplicationController
  def create
    if user_signed_in?
      current_user.update!(cookies_consent: sanitized_value)
    end

    cookies[:cookies_consent] = {
      value: sanitized_value,
      expires: 1.year.from_now,
      same_site: :lax
    }

    respond_to(&:turbo_stream)
  end

  private

  def sanitized_value
    value = params[:value].to_s
    value == 'accepted' ? :accepted : :declined
  end
end
