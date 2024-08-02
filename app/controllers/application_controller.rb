class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, except: [:switch_locale, :saml]

  before_action do
    if current_user && current_user.admin
      Rack::MiniProfiler.authorize_request
    end
  end

  before_action :load_objects_from_params
  before_action :update_ia_work_server
  before_action :store_current_location, :unless => :devise_controller?
  before_action :load_html_blocks
  before_action :authorize_collection
  before_action :configure_permitted_parameters, if: :devise_controller?
  skip_before_action :verify_authenticity_token, if: (:devise_controller? && :codespaces_environment?)
  before_action :set_current_user_in_model
  before_action :masquerade_user!
  before_action :check_search_attempt
  after_action :track_action
  around_action :switch_locale

  def switch_locale(&action)
    @dropdown_locales = I18n.available_locales.reject { |locale| locale.to_s.include? "-" }

    locale = nil

    # use user-record locale
    if user_signed_in? && !current_user.preferred_locale.blank?
      # the user has set their locale manually; use it.
      locale = current_user.preferred_locale
    end

    # if we can't find that, use session locale
    if locale.nil?
      if session[:current_locale]
        locale = session[:current_locale]
      end
    end

    # if we can't find that, use browser locale
    if locale.nil?
      # the user might their locale set in the browser
      locale = http_accept_language.preferred_language_from(I18n.available_locales)
    end

    if locale.nil? || !I18n.available_locales.include?(locale.to_sym)
      # use the default if the above optiosn didn't work
      locale = I18n.default_locale
    end

    # append region to locale
    related_locales = http_accept_language.user_preferred_languages.select do |loc|
      loc.to_s.include?(locale.to_s) &&                              # is related to the chosen locale (is the locale, or is a regional version of it)
      I18n.available_locales.map{|e| e.to_s}.include?(loc.to_s) # is an available locale
    end

    unless related_locales.empty?
      # first preferred language from the related locales
      locale = http_accept_language.preferred_language_from(related_locales)
    end

    # execute the action with the locale
    I18n.with_locale(locale, &action)
  end

  # Set the current user in User
  def set_current_user_in_model
    User.current_user = current_user
  end

  def current_user
    super || guest_user
  end

  #find the guest user account if a guest user session is currently active
  def guest_user
    unless session[:guest_user_id].nil?
      User.where(id: session[:guest_user_id]).first
    end
  end

  #when the user chooses to transcribe as guest, find guest user id or create new guest user
  def guest_transcription

    return head(:forbidden) unless GUEST_TRANSCRIPTION_ENABLED

    if check_recaptcha(model: @page, :attribute => :errors)
      User.find(session[:guest_user_id].nil? ? session[:guest_user_id] = create_guest_user.id : session[:guest_user_id])
      redirect_to :controller => 'transcribe', :action => 'display_page', :page_id => @page.id
    else
      # TODO: Get some kind of flash notification on failure
      flash[:error] = t('layouts.application.recaptcha_validation_failed')
      flash.keep
      redirect_to :controller => 'transcribe', :action => 'guest', :page_id => @page.id
    end

  end

  def create_guest_user
    user = User.new { |user| user.guest = true}
    user.email = "guest_#{Time.now.to_i}#{rand(99)}@example.com"
    user.save(:validate => false)
    user
  end

  def remove_col_id
    #if there's a col_id set, needs to be removed to prevent breadcrumb issues
    if session[:col_id]
      session[:col_id] = nil
    end
  end

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery :secret => 'I Hate InvalidAuthenticityToken'
  rescue_from ActiveRecord::RecordNotFound do |e|
    bad_record_id(e)
  end

  def load_objects_from_params
    # this needs to be ordered from the specific to the
    # general, so that parent_id will load the appropriate
    # object without being overridden by child_id.parent
    # whenever both are specified on the parameters

    if params[:article_id]
      @article = Article.find(params[:article_id])
      if session[:col_id] != nil
        @collection = set_friendly_collection(session[:col_id])
        session[:col_id] = nil
      else
        @collection = @article.collection
      end
    end
    if params[:page_id]
      @page = Page.find(params[:page_id])
      @work = @page.work
      if session[:col_id] != nil
        @collection = set_friendly_collection(session[:col_id])
        session[:col_id] = nil
      else
        @collection = @page.collection
      end
    end
    if params[:work_id]
      @work = Work.friendly.find(params[:work_id])
      @collection = @work.collection
    end
    if params[:document_set_id]
      @document_set = DocumentSet.friendly.find(params[:document_set_id])
      @collection = @document_set.collection
    end
    if params[:collection_id]
      @collection = set_friendly_collection(params[:collection_id])
    end

    if params[:user_id]
      @user = User.friendly.find(params[:user_id])
    end

    # category stuff may be orthogonal to collections and articles
    if params[:category_id]
      @category = Category.find(params[:category_id])
    end

    # consider loading work and collection from the versions
    if params[:page_version_id]
      @page_version = PageVersion.find(params[:page_version_id])
      @page = @page_version.page
      @work = @page.work
      @collection = @work.collection
    end
    if params[:article_version_id]
      @article_version = ArticleVersion.find(params[:article_version_id])
      @article = @article_version.article
      @collection = @article.collection
    end
    if params[:collection_ids]
      @collection_ids = params[:collection_ids]
    end


    if self.class.module_parent == Thredded && @collection
      Thredded::Engine.routes.default_url_options = { user_slug: @collection.owner.slug, collection_id: @collection.slug }
    else
      Thredded::Engine.routes.default_url_options = { user_slug: 'nil', collection_id: 'nil' }
    end

  end


  def set_friendly_collection(id)
    if Collection.friendly.exists?(id)
      @collection = Collection.friendly.find(id)
    elsif DocumentSet.friendly.exists?(id)
      @collection = DocumentSet.friendly.find(id)
    elsif !DocumentSet.find_by(slug: id).nil?
      @collection = DocumentSet.find_by(slug: id)
    elsif !Collection.find_by(slug: id).nil?
      @collection = Collection.find_by(slug: id)
    end

    # check to make sure URLs haven't gotten scrambled
    if @work
      if @work.collection != @collection
        # this could be a document set or a bad collection
        unless @collection.is_a? DocumentSet
          @collection = @work.collection
        end
      end
    end
    return @collection
  end

  def bad_record_id(e)
    logger.error("Bad record ID exception for params=#{params.inspect}")
    logger.error(e.backtrace[2])
    if @collection
      redirect_to :controller => 'collection', :action => 'show', :collection_id => @collection.id
    else
      redirect_to "/404"
    end

    return
  end

  # perform appropriate API call for updating the IA server
  def update_ia_work_server
    if @work && @work.ia_work
      ia_servers = session[:ia_servers] ||= {}
      ia_servers = JSON.parse(ia_servers.to_json).with_indifferent_access

      unless ia_servers[@work.ia_work.book_id]
        # fetch it and update it
        begin
          server_and_path = IaWork.refresh_server(@work.ia_work.book_id)
          ia_servers[@work.ia_work.book_id] = server_and_path
        rescue => ex
          # TODO log exception
          if params[:offline]
            # we're doing development offline
            ia_servers[@work.ia_work.book_id] = {:server => 'offlineserver', :ia_path => 'offlinepath'}
          else
            logger.error(ex.message)
            logger.error(ex.backtrace.join("\n"))
            flash[:error] = t('layouts.application.internet_archive_difficulties')
            redirect_to :controller => :collection, :action => :show, :collection_id => @collection.id
            return
          end
        end
      end

      logger.debug("DEBUG: ia_server = #{ia_servers[@work.ia_work.book_id].inspect}")
      @work.ia_work.server = ia_servers[@work.ia_work.book_id][:server]
      @work.ia_work.ia_path = ia_servers[@work.ia_work.book_id][:ia_path]
    end
  end

  def load_html_blocks
    @html_blocks = {}
    page_blocks =
      PageBlock.where(controller: controller_name, view: action_name)
    page_blocks.each do |b|
        if b && b.html
          b.rendered_html = render_to_string(:inline => b.html)
        else
          b.rendered_html = ''
        end
        @html_blocks[b.tag] = b
    end
  end

  def authorize_collection
    return unless @collection
    if self.class.module_parent.name == 'Thredded'
      unless @collection.messageboards_enabled
        flash[:error] = t('message_boards_are_disabled', :project => @collection.title)
        redirect_to main_app.user_profile_path(@collection.owner)
      end
    end

    return unless @collection.restricted
    return if (params[:controller] == 'iiif')

    unless @collection.show_to?(current_user)
      # second chance?
      unless set_fallback_collection
        flash[:error] = t('unauthorized_collection', :project => @collection.title)
        redirect_to main_app.user_profile_path(@collection.owner)
      end
    end
  end

  def set_fallback_collection
    if @work && @work.collection.supports_document_sets
      alternative_set = @work.document_sets.where(:is_public => true).first
      if alternative_set
        @collection = alternative_set
        true
      else
        false
      end
    else
      false
    end
  end


  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) { |u| u.permit(:login, :email, :password, :password_confirmation, :display_name, :owner, :paid_date, :activity_email) }
    devise_parameter_sanitizer.permit(:sign_in) { |u| u.permit(:login_id, :login, :email, :password, :remember_me) }
    devise_parameter_sanitizer.permit(:account_update) { |u| u.permit(:login, :email, :password, :current_password, :password_confirmation, :real_name) }
  end

  # Redirect to admin or owner dashboard after sign in
    # Always send admins to admin dashboard
    # Everyone else should go back to where they came from if their previous page is set
    # Otherwise owners should go to their dashboards
    # And everyone else should go to user dashboard/watchlist
  def after_sign_in_path_for(resource)
    if current_user.admin
      admin_path
    elsif !session[:user_return_to].blank? && session[:user_return_to] != '/' && !session[:user_return_to].include?('/landing')
      session[:user_return_to]
    elsif current_user.owner
      if current_user.collections.any?
        dashboard_owner_path
      else
        dashboard_startproject_path
      end
    else
      dashboard_watchlist_path
    end
  end

  # destroy guest user session if a user signs out, then redirect to root path
  def after_sign_out_path_for(resource)
    if session[:guest_user_id]
      session[:guest_user_id] = nil
    end
    root_path
  end

  # Wrapper around redirect_to for modal ajax forms
  def ajax_redirect_to(options={}, response_status={})
    if request.xhr?
      head :created, location: url_for(options)
    else
      redirect_to options, response_status
    end
  end

end

  def page_params(page)
    if page.status_new?
      if user_signed_in?
        collection_transcribe_page_path(@collection.owner, @collection, page.work, page)
      else
        collection_guest_page_path(@collection.owner, @collection, page.work, page)
      end
    else
      collection_display_page_path(@collection.owner, @collection, page.work, page)
    end
  end


  def track_action
    extras = {}
    if @collection
      if @collection.is_a? DocumentSet
        extras[:document_set_id] = @collection.id
        extras[:document_set_title] = @collection.title
        extras[:collection_id] = @collection.collection.id
        extras[:collection_title] = @collection.collection.title
      else
        extras[:collection_id] = @collection.id
        extras[:collection_title] = @collection.title
      end
    end
    extras[:work_id] = @work.id if @work
    extras[:work_title] = @work.title if @work
    extras[:page_id] = @page.id if @page
    extras[:page_title] = @page.title if @page
    extras[:article_id] = @article.id if @article
    extras[:article_title] = @article.title if @article
    ahoy.track("#{controller_name}##{action_name}", extras) unless action_name == "still_editing"
  end


  def check_api_access
    if (defined? @collection) && @collection
      if @collection.restricted && !@collection.api_access
        if @api_user.nil? || !(@api_user.like_owner?(@collection))
          render :status => 403, :plain => 'This collection is private.  The collection owner must enable API access to it or make it public for it to appear.'
        end
      end
    end
  end

  def set_api_user
    authenticate_with_http_token do |token, options|
      @api_user = User.find_by(api_key: token)
    end
  end

  def check_search_attempt
    if session[:search_attempt_id]
      your_profile = controller_name == "user" && @user == current_user
      if ["dashboard", "static"].include?(controller_name) || your_profile
        session[:search_attempt_id] = nil
      end
    end
  end

  def update_search_attempt_contributions
    if session[:search_attempt_id]
      search_attempt = SearchAttempt.find(session[:search_attempt_id])
      search_attempt.increment!(:contributions)
    end
  end

  def update_search_attempt_user(user, session_var)
    if session_var[:search_attempt_id]
      search_attempt = SearchAttempt.find(session_var[:search_attempt_id])
      search_attempt.user = user
      search_attempt.owner = user.owner
      search_attempt.save
    end
  end

private
  def store_current_location
    store_location_for(:user, request.url)
  end
  def check_recaptcha(options)
    return verify_recaptcha(options) if RECAPTCHA_ENABLED
    true
  end
  def codespaces_environment?
    Rails.env.development? && ENV["CODESPACES"] == "true"
  end
# class ApplicationController < ActionController::Base
#   protect_from_forgery
# end
