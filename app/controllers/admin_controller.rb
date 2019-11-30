class AdminController < ApplicationController
  include ErrorHelper

  before_action :authorized?

  PAGES_PER_SCREEN = 20

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:edit_user, :update_user, :new_owner, :expunge_confirmation, :expunge_user]

  def authorized?
    unless user_signed_in? && current_user.admin
      redirect_to dashboard_path
    end
  end

  def index
    @users = User.all
    @owners = User.where(owner: true)

    # Count stats for dashboard
    @collections_count  = Collection.all.count
    @articles_count     = Article.all.count
    @works_count        = Work.all.count
    @ia_works_count     = IaWork.all.count
    @pages_count        = Page.all.count
    @users_count        = User.all.count
    @owners_count       = User.where(owner: true).count

    @version = ActiveRecord::Migrator.current_version
=begin
    sql_online =
      'SELECT count(DISTINCT user_id) count '+
      'FROM interactions '+
      'WHERE created_on > date_sub(UTC_TIMESTAMP(), INTERVAL 20 MINUTE) '+
      'AND user_id IS NOT NULL'

    @users_count = Interaction.connection.select_value(sql_online)
=end
  end

  def user_list
    if params[:search]
      @users = User.search(params[:search]).order(created_at: :desc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    else
      @users = User.order(created_at: :desc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    end
  end

  def edit_user
  end

  def user_visits
    @visits = @user.visits.order(started_at: :desc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

  def visit_actions
    @visit = Visit.find(params[:visit_id])
    @actions = @visit.ahoy_events.order(time: :asc).paginate :page => params[:page], :per_page => 500
  end

  def visit_deeds
    @visit = Visit.find(params[:visit_id])
  end

  def update_user
    owner = @user.owner
    if @user.update(user_params)
      if owner == false && @user.owner == true
        if SMTP_ENABLED
          begin
            text = PageBlock.find_by(view: "new_owner").html
            UserMailer.new_owner(@user, text).deliver!
          rescue StandardError => e
            log_smtp_error(e, current_user)
          end
        end
      end

      flash[:notice] = "User profile has been updated"
      ajax_redirect_to :action => 'user_list'
    else
      render :action => 'edit_user'
    end
  end

  def delete_user
    @user.soft_delete
    #@user.destroy
    flash[:notice] = "User profile has been deleted"
    redirect_to :action => 'user_list'
  end

  def expunge_confirmation
  end

  def expunge_user
    @user.expunge
    flash[:notice] = "User #{@user.display_name} has been expunged"
    if params[:flag_id]
      ajax_redirect_to :action => 'revert_flag', :flag_id => params[:flag_id]
    else
      ajax_redirect_to :action => 'user_list'  # what if we came from the flag list?  TODO
    end
  end


  def flag_list
    @flags = Flag.where(:status => Flag::Status::UNCONFIRMED).order(:content_at => :desc).paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

  def revert_flag
    # find the flag
    flag = Flag.find(params[:flag_id])
    # revert the content
    flag.revert_content!
    # redirect to flag list at the appropriate page
    redirect_to :action => 'flag_list', :page => params[:page]
  end

  def ok_flag
    # find the flag
    flag = Flag.find(params[:flag_id])
    # revert the content
    flag.mark_ok!
    # redirect to flag list at the appropriate page
    redirect_to :action => 'flag_list', :page => params[:page]
  end

  def tail_logfile
    @lines = params[:lines].to_i
    development_logfile = "#{Rails.root}/log/development.log"
    production_logfile = "#{Rails.root}/log/production.log"
    @dev_tail = `tail -#{@lines} #{development_logfile}`
    @prod_tail = `tail -#{@lines} #{production_logfile}`
  end

  def autoflag
    flash[:notice] = "Looking for additional content to flag.  Revisit this page in a few minutes."

    cmd = "rake fromthepage:flag_abuse &"
    logger.info(cmd)
    system(cmd)

    redirect_to :action => 'flag_list', :page => params[:page]
  end

  def uploads
    @document_uploads = DocumentUpload.order('id DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
  end

  def delete_upload
    @document_upload = DocumentUpload.find(params[:id])
    @document_upload.destroy
    flash[:notice] = "Uploaded document has been deleted"
    redirect_to :action => 'uploads'
  end

  def process_upload
    @document_upload = DocumentUpload.find(params[:id])
    @document_upload.submit_process
    flash[:notice] = "Uploaded document has been queued for processing"
    redirect_to :action => 'uploads'
  end

  def view_processing_log
    @document_upload = DocumentUpload.find(params[:id])
    render :content_type => 'text/plain', :plain => `cat #{@document_upload.log_file}`, :layout => false
  end

  def collection_list
    @collections = Collection.order(:title).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
  end

  def work_list
    @collections = Collection.order(:title).paginate(:page => params[:page], :per_page => 10)
    @works = Work.order(:title)
  end

  def article_list
    @collections = Collection.all
  end

  def page_list
    @pages = Page.order(:title).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
  end

  def settings
    @email_text = PageBlock.find_by(view: "new_owner").html
    @flag_blacklist = PageBlock.find_by(view: "flag_blacklist").html
  end

  def update
    #need the original email text to update
    block = PageBlock.find_by(view: "new_owner")
    if params[:admin][:welcome_text] != block.html
      block.html = params[:admin][:welcome_text]
      block.save!
    end

    block = PageBlock.find_by(view: "flag_blacklist")
    if params[:admin][:flag_blacklist] != block.html
      block.html = params[:admin][:flag_blacklist]
      block.save!
    end

    flash[:notice] = "Admin settings have been updated"

    redirect_to action: 'settings'
  end

  def owner_list
    @collections = Collection.all
    #@owners = User.where(owner: true).order(paid_date: :desc).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
    if params[:search]
      @owners = User.search(params[:search]).where(owner: true).order(paid_date: :desc).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
    elsif params[:sort]
      sort = params[:sort]
      dir = params[:dir].upcase
      @owners = User.where(owner: true).order("#{sort} #{dir}").paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
    else
      @owners = User.where(owner: true).order(paid_date: :desc).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
    end
  end

  private

  def user_params
    params.require(:user).permit(:user, :owner)
  end
end
