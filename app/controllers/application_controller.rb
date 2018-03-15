class ApplicationController < ActionController::Base
  before_filter :load_objects_from_params
  before_filter :update_ia_work_server
  before_filter :update_omeka_urls
  before_action :store_current_location, :unless => :devise_controller?
  before_filter :load_html_blocks
  before_filter :authorize_collection
  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :set_current_user_in_model
  before_filter :masquerade_user!
  after_action :track_action

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
      User.find(session[:guest_user_id])
    end
  end

  #when the user chooses to transcribe as guest, find guest user id or create new guest user
  def guest_transcription
    User.find(session[:guest_user_id].nil? ? session[:guest_user_id] = create_guest_user.id : session[:guest_user_id])
    redirect_to :controller => 'transcribe', :action => 'display_page', :page_id => @page.id
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
  rescue_from ActiveRecord::RecordNotFound, with: :bad_record_id

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
    return @collection
  end

  def bad_record_id
    logger.error("Bad record ID exception for params=#{params.inspect}")
    if @collection 
      redirect_to :controller => 'collection', :action => 'show', :collection_id => @collection.id
    else
      redirect_to :controller => 'dashboard', :action => 'index'
    end
    return
  end


  def pontiiif_server
    Rails.application.config.respond_to?(:pontiiif_server) && Rails.application.config.pontiiif_server
  end


  def update_omeka_urls
    if @work && @work.omeka_item && @work.omeka_item.needs_refresh?
      @work.omeka_item.refresh_urls
    end    
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
            flash[:error] = "The Internet Archive is experiencing difficulties.  Please try again later."
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
    # skip irrelevant cases
    return unless @collection
    return unless @collection.restricted
    return if (params[:controller] == 'iiif')

    unless @collection.show_to?(current_user)
      redirect_to dashboard_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:login, :email, :password, :password_confirmation, :display_name) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login_id, :login, :email, :password, :remember_me) }

  end

  # Redirect to admin or owner dashboard after sign in
  def after_sign_in_path_for(resource)
    if current_user.admin
      admin_path
    elsif current_user.owner
      session[:user_return_to] || dashboard_owner_path      
    else
    session[:user_return_to] || dashboard_watchlist_path
    end
  end

#destroy guest user session if a user signs out, then redirect to root path
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
    if page.status == nil
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
    ahoy.track_visit
    extras = {}
    extras[:collection_id] = @collection.id if @collection
    extras[:collection_title] = @collection.title if @collection
    extras[:work_id] = @work.id if @work
    extras[:work_title] = @work.title if @work
    extras[:page_id] = @page.id if @page
    extras[:page_title] = @page.title if @page
    extras[:article_id] = @article.id if @article
    extras[:article_title] = @article.title if @article
    ahoy.track("#{controller_name}##{action_name}", extras)
  end

private
  def store_current_location
    store_location_for(:user, request.url)
  end

# class ApplicationController < ActionController::Base
#   protect_from_forgery
# end
