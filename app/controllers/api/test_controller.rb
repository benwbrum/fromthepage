class Api::TestController < ApplicationController

  def index
    @marks = [{"lala":'lalala'},{"lala":'lalala1'}]
    render json: @marks
  end
 
end
