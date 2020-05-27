require 'gamification_helper'
require 'semantic_helper'

class Api::ApiController < ApplicationController
  
  include I18nHelper
  
  before_action :set_locale
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
    begin
      options = getSerializationOptions(object.data, params[:fields])
      render json: object, :include => options[:include], :methods => options[:methods]
    rescue
      render json: object
    end
  end
  
  def response_serialized_object(object)
    render_serialized ResponseWS.default_ok(object)
  end
  
  private
    def _not_signed_error
      return ResponseWS.simple_error('api.session.not_allowed')
    end
    
    def get_fields(fields_s)
      fields = []
      if(params[:fields] != nil)
        fields = fields_s.split(',').grep(/^[^:]/).map &:to_sym
      end
    end
    
    def getSerializationOptions(object, fields_s)
      options = { :include => [], :methods => [] }
      if(fields_s != nil)
        fields = fields_s.split(',').grep(/^[^:]/).map &:to_sym
        fields.each { | field | object.class.method_defined?(field)? options[:methods].push(field) : options[:include].push(field) }
      end
      print options.inspect 
      return options
    end
end
