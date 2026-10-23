class SessionsController < Devise::SessionsController
  def create
    super do |user|
      consent_cache = ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_recorded]) || false

      privacy_preference = user.privacy_preference || user.build_privacy_preference

      next if privacy_preference.recorded

      next unless consent_cache

      privacy_preference.recorded = true
      privacy_preference.marketing = ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_marketing])
      privacy_preference.analytics = ActiveRecord::Type::Boolean.new.cast(cookies[:cookies_analytics])
      privacy_preference.save!
    end
  end

  private

  def show_consent_banner?
    false
  end
end
