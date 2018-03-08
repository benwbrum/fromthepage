class Api::ApiDeviceRegistrationController < Devise::RegistrationsController
  
  include I18nHelper
  
  before_action :set_locale
#  before_action :authorized?
  
 
  
  def render_serialized(object)
    render json: object
  end
  
  def response_serialized_object(object)
    render_serialized ResponseWS.default_ok(object)
  end
  
  private
    def _not_signed_error
      return ResponseWS.simple_error('api.session.not_allowed')
    end
end

