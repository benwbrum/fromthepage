class Cookies::Lib::CreateOrUpdateHandler
  attr_accessor :cookies

  def initialize(cookies:, privacy_preference_params:, user:)
    @cookies = cookies
    @privacy_preference_params = privacy_preference_params
    @user = user
  end

  def perform
    if @user.present?
      privacy_preference.marketing = marketing_value
      privacy_preference.analytics = analytics_value

      privacy_preference.recorded = true
      privacy_preference.save!
    end

    set_cookie(:cookies_recorded, true)
    set_cookie(:cookies_marketing, marketing_value)
    set_cookie(:cookies_analytics, analytics_value)

    self
  end

  private

  def privacy_preference
    @user.privacy_preference || @user.build_privacy_preference
  end

  def marketing_value
    @marketing_value ||= ActiveRecord::Type::Boolean.new.cast(@privacy_preference_params[:marketing])
  end

  def analytics_value
    @analytics_value ||= ActiveRecord::Type::Boolean.new.cast(@privacy_preference_params[:analytics])
  end

  def set_cookie(key, value)
    @cookies[key] = {
      value: value,
      expires: 1.year.from_now,
      same_site: :lax
    }
  end
end
