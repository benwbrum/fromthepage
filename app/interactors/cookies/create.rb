class Cookies::Create < ApplicationInteractor
  attr_accessor :cookies

  def initialize(cookies:, privacy_preference_params:, user:)
    @cookies = cookies
    @privacy_preference_params = privacy_preference_params
    @user = user

    super
  end

  def perform
    handler = Cookies::Lib::CreateOrUpdateHandler.new(
      cookies: @cookies,
      privacy_preference_params: @privacy_preference_params,
      user: @user
    )

    handler.perform
    @cookies = handler.cookies
  end
end
