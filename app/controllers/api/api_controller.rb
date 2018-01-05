class Api::ApiController < ApplicationController
  
  before_action :authorized?
  
  def authorized?
    unless public_actions.include? action_name.to_sym
      unless user_signed_in?
        puts "*** User not signed ***"
        render_serialized _not_signed_error
      else
        puts "*** Signed in as " + current_user.login + "! ***"
      end
    else
      puts "*** Public Action ***"
    end
  end
  
  def public_actions
    return []
  end
  
  def render_serialized(object)
    render json: object
  end
  
  private
    def _not_signed_error
      return ResponseWS.simple_error("Para acceder a este contenido debes iniciar sesión")
    end
end
