class UserController < ApplicationController
  def demo
    session[:demo_mode] = true;
    redirect_to :controller => 'dashboard'
  end
end
