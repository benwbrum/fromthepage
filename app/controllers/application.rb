# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require_dependency "login_system"

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include AuthenticatedSystem
  before_filter :load_objects_from_params
  before_filter :set_current_user_in_model
  before_filter :log_interaction
  before_filter :store_location_for_login
  after_filter :complete_interaction

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery :secret => '84a8eb6b8cd3ab40640d70c396f27334'


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
  
  # Set the current user in User
  def set_current_user_in_model
    User.current_user = current_user
  end 

  # log what was done
  def log_interaction
    @interaction = Interaction.new
    @interaction.session_id = session.session_id
    @interaction.browser = request.env['HTTP_USER_AGENT']
    @interaction.ip_address = request.env['REMOTE_ADDR']
    if(logged_in?)
      @interaction.user_id = current_user.id
    end
    @interaction.params = params.reject{|k,v| k=='password'}.inspect
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

  
  def store_location_for_login
    unless action_name == 'login'
      store_location
    end
  end
end
