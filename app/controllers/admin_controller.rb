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
    
    transcription_deeds = Deed.where(deed_type: DeedType.transcriptions_or_corrections_no_edits)
    contributor_deeds = Deed.where(deed_type: DeedType.contributor_types)

    # Count stats for dashboard
    @pages_per_hour         = transcription_deeds.where("created_at between ? and ?", Time.now - 1.hour, Time.now).count
    @contributions_per_hour = contributor_deeds.where("created_at between ? and ?", Time.now - 1.hour, Time.now).count
    @collections_count      = Collection.all.count
    @articles_count         = Article.all.count
    @works_count            = Work.all.count
    @ia_works_count         = IaWork.all.count
    @pages_count            = Page.all.count
    @transcribed_count      = Page.where.not(status: nil).count
    @notes_count            = Note.all.count
    @users_count            = User.all.count
    @owners_count           = User.where(owner: true).count
    
    @transcription_counts = {}
    @contribution_counts = {}
    @activity_project_counts = {}
    @unique_contributor_counts = {}
    @week_intervals=[1,2,4,12,26,52,104,156,208]
    @week_intervals.each do |weeks_ago|
      start_date = Date.yesterday - weeks_ago.weeks
      end_date = start_date + 1.week
      @transcription_counts[weeks_ago] = transcription_deeds.where("created_at between ? and ?", start_date, end_date).count
      @contribution_counts[weeks_ago] = contributor_deeds.where("created_at between ? and ?", start_date, end_date).count
      @activity_project_counts[weeks_ago] = contributor_deeds.where("created_at between ? and ?", start_date, end_date).distinct.count(:collection_id)
      @unique_contributor_counts[weeks_ago] = contributor_deeds.where("created_at between ? and ?", start_date, end_date).distinct.count(:user_id)
    end

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

      flash[:notice] = t('.user_profile_updated')
      if owner
        ajax_redirect_to :action => 'owner_list'
      else
        ajax_redirect_to :action => 'user_list'
      end
  
    else
      render :action => 'edit_user'
    end
  end

  def delete_user
    @user.soft_delete
    #@user.destroy
    flash[:notice] = t('.user_profile_deleted')
    redirect_to :action => 'user_list'
  end

  def expunge_confirmation
  end

  def expunge_user
    @user.expunge
    flash[:notice] = t('.user_expunged', user: @user.display_name)
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

  def ok_user
    flag = Flag.find(params[:flag_id])
    flag.ok_user
    redirect_to :action => 'flag_list', :page => params[:page]
  end

  def tail_logfile
    @lines = params[:lines].to_i
    if @lines == 0
      @lines=5000
    end
    development_logfile = "#{Rails.root}/log/development.log"
    production_logfile = "#{Rails.root}/log/production.log"
    @dev_tail = `tail -#{@lines} #{development_logfile}`
    @prod_tail = `tail -#{@lines} #{production_logfile}`
  end

  def autoflag
    flash[:notice] = t('.flag_message')

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
    flash[:notice] = t('.uploaded_document_deleted')
    redirect_to :action => 'uploads'
  end

  def process_upload
    @document_upload = DocumentUpload.find(params[:id])
    @document_upload.submit_process
    flash[:notice] = t('.uploaded_document_queued')
    redirect_to :action => 'uploads'
  end

  def view_processing_log
    @document_upload = DocumentUpload.find(params[:id])
    render :content_type => 'text/plain', :plain => `cat #{@document_upload.log_file}`, :layout => false
  end

  def collection_list
    @collections = Collection.order(:title)
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
    @flag_denylist = PageBlock.find_by(view: "flag_denylist").html
    @email_denylist = (PageBlock.where(view: "email_denylist").first ? PageBlock.where(view: "email_denylist").first.html : '')
  end

  def update
    #need the original email text to update
    block = PageBlock.find_by(view: "new_owner")
    if params[:admin][:welcome_text] != block.html
      block.html = params[:admin][:welcome_text]
      block.save!
    end

    block = PageBlock.find_by(view: "flag_denylist")
    if params[:admin][:flag_denylist] != block.html
      block.html = params[:admin][:flag_denylist]
      block.save!
    end

    block = PageBlock.where(view: "email_denylist").first || PageBlock.new(view: 'email_denylist')
    if params[:admin][:email_denylist] != block.html
      block.html = params[:admin][:email_denylist]
      block.save!
    end


    flash[:notice] = t('.admin_settings_updated')

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
      @owners = User.where(owner: true).order(created_at: :desc).paginate(:page => params[:page], :per_page => PAGES_PER_SCREEN)
    end
  end

  def downgrade
    u = User.find(params[:user_id])
    u.downgrade
    redirect_back fallback_location: { action: 'user_list' }, notice: t('.user_downgraded_successfully')
  end

  def moderation
    @collections = Collection.where(messageboards_enabled:true)
  end

  def searches
    if params[:filter]
      @searches = SearchAttempt.where(owner: false).order('id DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    else
      @searches = SearchAttempt.order('id DESC').paginate :page => params[:page], :per_page => PAGES_PER_SCREEN
    end

    this_week = SearchAttempt.where('created_at > ?', 1.week.ago)
    @searches_per_day = (this_week.count / 7.0).round(2)
    @average_hits = this_week.average(:hits).round(2)
    @clickthrough_rate = ((this_week.where('clicks > 0').count.to_f / this_week.count.to_f) * 100).round(1)
    @clickthrough_rate_visit = (this_week.joins(:visit).group('visits.id').sum(:clicks).values.count{|c|c>0}.to_f / this_week.joins(:visit).group('visits.id').length).round(3) * 100
    @contribution_rate = ((this_week.where('contributions > 0').count.to_f / this_week.count.to_f) * 100).round(1) 
    @contribution_rate_visit = (this_week.joins(:visit).group('visits.id').sum(:contributions).values.count{|c|c>0}.to_f / this_week.joins(:visit).group('visits.id').length).round(3) * 100
  end

  private

  def user_params
    params.require(:user).permit(:real_name, :login, :email, :account_type, :start_date, :paid_date, :user, :owner)
  end
end
