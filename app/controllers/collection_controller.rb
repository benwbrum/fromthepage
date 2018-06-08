# handles administrative tasks for the collection object
class CollectionController < ApplicationController
  include ContributorHelper
  include AddWorkHelper
  include CollectionHelper

  public :render_to_string

  protect_from_forgery :except => [:set_collection_title,
                                   :set_collection_intro_block,
                                   :set_collection_footer_block]

  before_filter :authorized?, :only => [:new, :edit, :update, :delete, :works_list]
  before_action :set_collection, :only => [:show, :edit, :update, :contributors, :new_work, :works_list, :needs_transcription_pages, :needs_review_pages, :start_transcribing]
  before_filter :load_settings, :only => [:edit, :update, :upload]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create]

  def authorized?
    
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def enable_document_sets
    @collection.supports_document_sets = true
    @collection.save!
    redirect_to document_sets_path(collection_id: @collection)
  end

  def disable_document_sets
    @collection.supports_document_sets = false
    @collection.save!
    redirect_to edit_collection_path(@collection.owner, @collection)
  end

  def load_settings
    @main_owner = @collection.owner
    @owners = [@main_owner] + @collection.owners
    @nonowners = User.order(:display_name) - @owners
    @nonowners.each { |user| user.display_name = user.login if user.display_name.empty? }
    @works_not_in_collection = current_user.owner_works - @collection.works
    @collaborators = @collection.collaborators
    @noncollaborators = User.order(:display_name) - @collaborators - @collection.owners
  end

  def show
    if @collection.restricted
      ajax_redirect_to dashboard_path unless user_signed_in? && @collection.show_to?(current_user)
    end

    if params[:search]
      @works = @collection.search_works(params[:search]).includes(:work_statistic).paginate(page: params[:page], per_page: 10)
    #show all works
    elsif (params[:works] == 'show')
      @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
    #hide incomplete works
    elsif params[:works] == 'hide' || (@collection.hide_completed)
      #find ids of completed translation works
      translation_ids = @collection.works.incomplete_translation.pluck(:id)
      #find ids of completed transcription works
      transcription_ids = @collection.works.incomplete_transcription.pluck(:id)
      #combine ids anduse to get works that aren't complete
      ids = translation_ids + transcription_ids
      @works = @collection.works.includes(:work_statistic).where(id: ids).paginate(page: params[:page], per_page: 10)
    else
      @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
    end
  end

  def owners
    @main_owner = @collection.owner
    @owners = @collection.owners + [@main_owner]
    @nonowners = User.all - @owners
  end

  def add_owner
    @user.owner = true
    @user.save!
    @collection.owners << @user
    @user.notification.owner_stats = true
    @user.notification.save!
    if @user.notification.add_as_owner
      send_email(@user, @collection)
    end
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def remove_owner
    @collection.owners.delete(@user)
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def add_collaborator
    @user = User.find_by(id: params[:collaborator_id])
    @collection.collaborators << @user
    if @user.notification.add_as_collaborator
      send_email(@user, @collection)
    end
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def remove_collaborator
    @collection.collaborators.delete(@user)
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def send_email(user, collection)
    if SMTP_ENABLED
      begin
        UserMailer.collection_collaborator(user, collection).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end
  end

  def publish_collection
    @collection.restricted = false
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def restrict_collection
    @collection.restricted = true
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def enable_fields
    @collection.field_based = true
    @collection.voice_recognition = false
    @collection.language = nil
    @collection.save!
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def disable_fields
    @collection.field_based = false
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection
  end

  def delete
    @collection.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @collection = Collection.new
  end

  def edit
    @text_languages = ISO_639::ISO_639_2.map {|lang| [lang[3], lang[0]]}
    @ssl = Rails.env.production? ? Rails.application.config.force_ssl : true
    #array of languages
    array = Collection::LANGUAGE_ARRAY

    #set language to default if it doesn't exist

    lang = !@collection.language.blank? ? @collection.language : "en-US"
    #find the language portion of the language/dialect or set to nil
    part = lang.split('-').first
    #find the index of the language in the array (transform to integer)
    @lang_index = array.size.times.select {|i| array[i].include?(part)}[0]
    #then find the index of the nested dialect within the language array
    int = array[@lang_index].size.times.select {|i| array[@lang_index][i].include?(lang)}[0]
    #transform to integer and subtract 2 because of how the array is nested
    @dialect_index = !int.nil? ? int-2 : nil
  end

  def update
    if params[:dialect]
      @collection.language = params[:dialect]
    end
    if params[:collection][:slug] == ""
      @collection.update(params[:collection].except(:slug))
      title = @collection.title.parameterize
      @collection.update(slug: title)
    else
      @collection.update(params[:collection])
    end

    if @collection.save!
      flash[:notice] = 'Collection has been updated'
      redirect_to action: 'edit', collection_id: @collection.id
    else
      render action: 'edit'
    end
  end

  # tested
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    @collection.owner = current_user
    if @collection.save
      flash[:notice] = 'Collection has been created'
      if request.referrer.include?('sc_collections')
        session[:iiif_collection] = @collection.id
        ajax_redirect_to(request.referrer)
      else
        ajax_redirect_to({ controller: 'dashboard', action: 'startproject', collection_id: @collection.id })
      end
    else
      render action: 'new'
    end
  end

  def add_work_to_collection
    logger.debug("DEBUG collection1=#{@collection}")
    set_collection_for_work(@collection, @work)
    logger.debug("DEBUG collection2=#{@collection}")
    #redirect_to action: 'edit', collection_slug: @collection.slug
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def remove_work_from_collection
    set_collection_for_work(nil, @work)
    #redirect_to action: 'edit', collection_slug: @collection.slug
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def new_work
    @work = Work.new
    @work.collection = @collection
    @document_upload = DocumentUpload.new
    @document_upload.collection=@collection
    @omeka_items = OmekaItem.all
    @omeka_sites = current_user.omeka_sites
    @universe_collections = ScCollection.universe
    @sc_collections = ScCollection.all
  end

  def contributors
    #Get the start and end date params from date picker, if none, set defaults
    start_date = params[:start_date]
    end_date = params[:end_date]
    
    if start_date == nil
      start_date = 1.week.ago
      end_date = DateTime.now.utc
    end

    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day

    @start_deed = start_date.strftime("%b %d, %Y")
    @end_deed = end_date.strftime("%b %d, %Y")

    
    new_contributors(@collection, start_date, end_date)
    @stats = @collection.get_stats_hash(start_date, end_date)
  end

  def contributors_download
    id = @collection.id
    start_date = params[:start_date]
    end_date = params[:end_date]

    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day

    new_contributors(@collection, start_date, end_date)

    headers = [
      :name, 
      :email,
      :user_total_minutes,
      :user_proportional_minutes,
    ]

    stats = @active_transcribers.map do |user|
      time_total = 0
      time_proportional = 0
    
      if @user_time[user.id]
        time_total = (@user_time[user.id] / 60 + 1).floor
      end

      if @user_time_proportional[user.id]
        time_proportional = (@user_time_proportional[user.id] / 60 + 1).floor
      end

      [
        user.display_name,
        user.email,
        time_total,
        time_proportional,
      ]
    end

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      stats.each do |user|
          records << user
      end
    end

    send_data( csv, 
      :filename => "#{start_date.strftime('%Y-%m%b-%d')}-#{end_date.strftime('%Y-%m%b-%d')}_#{@collection.slug}.csv",
      :type => "application/csv")

    cookies['download_finished'] = 'true'
      
  end

  def blank_collection
    collection = Collection.find_by(id: params[:collection_id])
    collection.blank_out_collection
    redirect_to action: 'show', collection_id: params[:collection_id]
  end

  def works_list
    if params[:sort_by] == "Percent Complete"
      @works = @collection.works.includes(:work_statistic).order_by_completed.paginate(page: params[:page], per_page: 15)
    elsif params[:sort_by] == "Recent Activity"
      @works = @collection.works.includes(:work_statistic).order_by_recent_activity.paginate(page: params[:page], per_page: 15)
    else
      @works = @collection.works.includes(:work_statistic).order(:title).paginate(page: params[:page], per_page: 15)
    end
  end

  def needs_transcription_pages
    work_ids = @collection.works.pluck(:id)
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).needs_transcription.order(work_id: :asc, position: :asc).paginate(page: params[:page], per_page: 10)
  end

  def needs_review_pages
    work_ids = @collection.works.pluck(:id)
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).review.paginate(page: params[:page], per_page: 10)
  end

  def start_transcribing
    pages = find_transcribe_pages
    if pages.blank?
      flash[:notice] = "Sorry, but there are no qualifying pages in this collection."
      redirect_to collection_path(@collection.owner, @collection)
    else
      @page = pages.first
      if !user_signed_in?
        redirect_to collection_guest_page_path(@page.collection.owner, @page.collection, @page.work, @page)
      else
        redirect_to collection_transcribe_page_path(@page.collection.owner, @page.collection, @page.work, @page)
      end
    end
  end

private
  def set_collection
    unless @collection
      if Collection.friendly.exists?(params[:id])
        @collection = Collection.friendly.find(params[:id])
      elsif DocumentSet.friendly.exists?(params[:id])
        @collection = DocumentSet.friendly.find(params[:id])
      elsif !DocumentSet.find_by(slug: params[:id]).nil?
        @collection = DocumentSet.find_by(slug: params[:id])
      elsif !Collection.find_by(slug: params[:id]).nil?
        @collection = Collection.find_by(slug: params[:id])
      end
    end
  end

  def set_collection_for_work(collection, work)
    # first update the id on the work
    work.collection = collection
    work.save!
    # then update the id on the articles
    # consider moving this to the work model?
    for article in work.articles
      article.collection = collection
      article.save!
    end
  end
end
