class ApplicationController < ActionController::Base
  before_filter :load_objects_from_params
  before_filter :update_ia_work_server
  before_filter :log_interaction
  # before_filter :store_location_for_login
  before_filter :load_html_blocks
  # after_filter :complete_interaction
  before_filter :authorize_collection
  before_filter :configure_permitted_parameters, if: :devise_controller?

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery :secret => 'I Hate InvalidAuthenticityToken'

  def load_objects_from_params

    # this needs to be ordered from the specific to the
    # general, so that parent_id will load the appropriate
    # object without being overridden by child_id.parent
    # whenever both are specified on the parameters
    if params[:article_id]
      @article = Article.find(params[:article_id])
      @collection = @article.collection
    end
    if params[:page_id]
      @page = Page.find(params[:page_id])
      @work = @page.work
      @collection = @work.collection
    end
    if params[:work_id]
      @work = Work.find(params[:work_id])
      @collection = @work.collection
    end
    if params[:collection_id]
      @collection = Collection.find(params[:collection_id])
    end

    # image stuff is orthogonal to collections
    if params[:titled_image_id]
      @titled_image = TitledImage.find(params[:titled_image_id])
      @image_set = @titled_image.image_set
    end
    if params[:image_set_id]
      @image_set = ImageSet.find(params[:image_set_id])
    end
    if params[:user_id]
      @user = User.find(params[:user_id])
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
  end

  # perform appropriate API call for updating the IA server
  def update_ia_work_server
    if @work && @work.ia_work
      ia_servers = session[:ia_servers] ||= {}
      unless ia_servers[@work.ia_work.book_id]
        # fetch it and update it
        server_and_path = IaWork.refresh_server(@work.ia_work.book_id)
        ia_servers[@work.ia_work.book_id] = server_and_path
      end
      logger.debug("DEBUG: ia_server = #{ia_servers[@work.ia_work.book_id].inspect}")
      @work.ia_work.server=ia_servers[@work.ia_work.book_id][:server]
      @work.ia_work.ia_path=ia_servers[@work.ia_work.book_id][:ia_path]
    end
  end

  # log what was done
  def log_interaction
    @interaction = Interaction.new
    if !session.respond_to?(:session_id)
      @interaction.session_id = Interaction.count + 1
    else
      @interaction.session_id = session.session_id
    end

    @interaction.browser = request.env['HTTP_USER_AGENT']
    @interaction.ip_address = request.env['REMOTE_ADDR']
    if(user_signed_in?)
      @interaction.user_id = current_user.id
    end
    clean_params = params.reject{|k,v| k=='password'}
    if clean_params['user']
      clean_params['user'] = clean_params['user'].reject{|k,v| k=~/password/}
    end

    @interaction.params = clean_params.inspect

    @interaction.status = 'incomplete'
    # app specific stuff
    @interaction.action = action_name
    if @collection
      @interaction.collection_id = @collection.id
    end
    if @work
      @interaction.work_id = @work.id
    end
    if @page
      @interaction.page_id = @page.id
    end
    @interaction.save
  end

  def complete_interaction
    @interaction.update_attribute(:status, 'complete')
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

  def store_location_for_login
    unless action_name == 'login' || action_name == 'signup'
      store_location
    end
  end

  def authorize_collection
    # skip irrelevant cases
    return unless @collection
    return unless @collection.restricted

    unless user_signed_in? && current_user.like_owner?(@collection)
      redirect_to dashboard_path
    end
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:login, :email, :password, :password_confirmation) }
  end
end

# class ApplicationController < ActionController::Base
#   protect_from_forgery
# end
