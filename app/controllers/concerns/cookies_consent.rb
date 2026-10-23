module CookiesConsent
  extend ActiveSupport::Concern

  included do
    helper_method :privacy_preference, :cookies_consent_status, :analytics_enabled?, :marketing_enabled?, :show_consent_banner?
  end

  private

  def cookies_consent_status
    if user_signed_in?
      cookies[:cookies_recorded] = {
        value: (privacy_preference&.recorded ? true : false),
        expires: 1.year.from_now,
        same_site: :lax
      }

      cookies[:cookies_marketing] = {
        value: (privacy_preference&.marketing || false),
        expires: 1.year.from_now,
        same_site: :lax
      }

      cookies[:cookies_analytics] = {
        value: (privacy_preference&.analytics || false),
        expires: 1.year.from_now,
        same_site: :lax
      }
    else
      cookies[:cookies_recorded] ||= {
        value: false,
        expires: 1.year.from_now,
        same_site: :lax
      }
    end

    ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_recorded])
  end

  def analytics_enabled?
    if privacy_preference.present?
      privacy_preference.analytics
    else
      ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_analytics])
    end
  end

  def marketing_enabled?
    if privacy_preference.present?
      privacy_preference.marketing
    else
      ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_marketing])
    end
  end

  def show_consent_banner?
    !cookies_consent_status
  end

  def privacy_preference
    current_user&.privacy_preference
  end
end
