class Api::ApiController < ApplicationController
  
  before_action :authorized?
  
  def authorized?
    unless public_actions.include? action_name.to_sym
      unless user_signed_in?
        logger.debug "[ACCESS] #{controller_name}##{action_name} -> User not authorized"
        render_serialized _not_signed_error
      else
        logger.debug "[ACCESS] #{controller_name}##{action_name} -> Signed as #{current_user.login}"
      end
    else
      logger.debug "[ACCESS] #{controller_name}##{action_name} -> Public action"
    end
  end
  
  def public_actions
    return []
  end
  
  def render_serialized(object)
    render json: object
  end
  
  def response_serialized_object(object)
    render_serialized ResponseWS.default_ok(object)
  end
  
  private
    def _not_signed_error
      return ResponseWS.simple_error("Para acceder a este contenido debes iniciar sesión")
    end
end
