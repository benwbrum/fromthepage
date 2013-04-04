class AccountController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem
  # If you want "remember me" functionality, add this before_filter to Application Controller
  before_filter :login_from_cookie

  # say something nice, you goof!  something sweet.
  def index
    redirect_to(:action => 'signup') unless logged_in? || User.count > 0
  end

  def signin
    return unless request.post?
    logger.debug "In accountcontroller signin"
    self.current_user = User.authenticate(params[:login], params[:password])
    if logged_in?
      logger.debug "User is logged in"
      if params[:remember_me] == "1"
        self.current_user.remember_me
        cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
      end
      redirect_back_or_default(:controller => 'dashboard', :action => 'index')
      flash[:notice] = "Logged in successfully"
    else
      logger.debug "User is NOT logged in"
      if (User.find_by_login(params[:login])) 
        flash[:error] = 
          "Your login and password did not match.  Feel free to contact alpha.info@fromthepage.com for help."
      else
        flash[:error] = "We could not find any user with the login #{params[:login]}.  Feel free to contact alpha.info@fromthepage.com for help."
      end
    end

  end

  def login
  end

  def signup
    @user = User.new
  end

  def process_signup
    logger.debug("in process_signup ---------------------")
    logger.debug("Here is request.post?: #{request.post?}")
    @user = User.new # (params[:user])
    @user.login = params[:user][:login]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    @user.display_name = params[:user][:display_name]
    @user.print_name = params[:user][:print_name]
    @user.email = params[:user][:email]
    return unless request.post?

    if request.post?
    # if verify_recaptcha
      logger.debug "It's good!!!!!!!!!!!!!!!!!!!!!!!!"
      @user.save!
      self.current_user = @user
      flash[:notice] = "Thanks for signing up!"
      redirect_back_or_default(:controller => 'dashboard', :action => 'index')
    else
      logger.debug "It's Bad :(((((((((((((((((((((((((((((((((("
      flash[:error] = "There was an error with the recaptcha code below. Please re-enter the code and click submit."
      render :action => 'new'
    end 
    
  rescue ActiveRecord::RecordInvalid
    render :action => 'signup'
  end
  
  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(:controller => 'dashboard', :action => 'index')
  end

end
