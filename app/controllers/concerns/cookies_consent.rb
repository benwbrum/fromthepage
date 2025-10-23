module CookiesConsent
  extend ActiveSupport::Concern

  included do
    helper_method :cookies_consent_status, :cookies_consented?, :show_consent_banner?
  end

  private

  def cookies_consent_status
    if user_signed_in?
      cookies[:cookies_consent] = {
        value: current_user.cookies_consent.to_sym,
        expires: 1.year.from_now,
        same_site: :lax
      }
    else
      cookies[:cookies_consent] ||= {
        value: :pending,
        expires: 1.year.from_now,
        same_site: :lax
      }
    end

    cookies[:cookies_consent].to_sym
  end

  def cookies_consented?
    cookies_consent_status == :accepted
  end

  def show_consent_banner?
    cookies_consent_status == :pending
  end
end
