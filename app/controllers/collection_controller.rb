# handles administrative tasks for the collection object
class CollectionController < ApplicationController
  include ContributorHelper
  include AddWorkHelper
  include CollectionHelper

  public :render_to_string

  protect_from_forgery :except => [:set_collection_title,
                                   :set_collection_intro_block,
                                   :set_collection_footer_block]

  before_action :authorized?, :only => [:new, :edit, :update, :delete, :works_list]
  before_action :review_authorized?, :only => [:reviewer_dashboard, :works_to_review, :one_off_list, :recent_contributor_list, :user_contribution_list]
  before_action :set_collection, :only => [:show, :edit, :update, :contributors, :new_work, :works_list, :needs_transcription_pages, :needs_review_pages, :start_transcribing]
  before_action :load_settings, :only => [:edit, :update, :upload, :edit_owners, :remove_owner, :edit_collaborators, :remove_collaborator, :edit_reviewers, :remove_reviewer]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create, :edit_buttons, :edit_owners, :remove_owner, :add_owner, :edit_collaborators, :remove_collaborator, :add_collaborator, :edit_reviewers, :remove_reviewer, :add_reviewer]

  def authorized?
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def search_users
    query = "%#{params[:term]}%"
    users = User.where("real_name like ? or email like ?", query, query)
    render json: { results: users.map{|u| {text: "#{u.display_name} #{u.email}", id: u.id}}}
  end

  def reviewer_dashboard
    # works which have at least one page needing review
    @one_off_page_count = @collection.pages_needing_review_for_one_off.count
    @unreviewed_users = @collection.never_reviewed_users
    @total_pages=@collection.pages.count
    @pages_needing_review=@collection.pages.where(status: Page::STATUS_NEEDS_REVIEW).count
    @transcribed_pages=@collection.pages.where(status: Page::NOT_INCOMPLETE_STATUSES).count
    @works_to_review = @collection.pages.where(status: Page::STATUS_NEEDS_REVIEW).pluck(:work_id).uniq.count
  end

  def works_to_review
    @works = @collection.works.joins(:work_statistic).includes(:notes, :pages).where.not('work_statistics.needs_review' => 0).reorder("works.title")
  end

  def one_off_list
    @pages = @collection.pages_needing_review_for_one_off
  end

  def recent_contributor_list
    @unreviewed_users = @collection.never_reviewed_users
  end

  def user_contribution_list
    #pages_needing_review = @user.deeds.where(collection_id: @collection.id).where(deed_type: DeedType.transcriptions_or_corrections).joins(:page).where("pages.status = ?", Page::STATUS_NEEDS_REVIEW)
    needs_review_page_ids = @user.deeds.where(collection_id: @collection.id).where(deed_type: DeedType.transcriptions_or_corrections).joins(:page).where("pages.status = ?", Page::STATUS_NEEDS_REVIEW).pluck(:page_id)
    @pages = Page.find(needs_review_page_ids)
  end

  def edit_buttons
    @prefer_html = @collection.editor_buttons.where(:prefer_html => true).exists?
  end

  def update_buttons
    @collection.editor_buttons.delete_all

    prefer_html = (params[:prefer_html] == 'true')

    EditorButton::BUTTON_MAP.keys.each do |key|
      if params[key] == "1"
        button_config = EditorButton.new
        button_config.key = key
        button_config.prefer_html = prefer_html
        button_config.collection = @collection
        button_config.save
      end
    end

    flash[:notice] = 'Editor Buttons Updated'
    ajax_redirect_to(edit_collection_path(@collection.owner, @collection))

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

  def facets
    collection = Collection.find(params[:collection_id])
    @metadata_coverages = collection.metadata_coverages
  end

  def search
    mc = @collection.metadata_coverages.where(key: params['facet_search']['label']).first
    first_year = params['facet_search']['date'].split.first.to_i
    last_year = params['facet_search']['date'].split.last.to_i
    order = params['facet_search']['date_order'].to_i
    years = (first_year..last_year).to_a
    date_order = "d#{order}"
    year = "w.work_facet.#{date_order}.year"

    facets = []

    @collection.works.each do |w|
      unless w.work_facet.nil?
        if years.include?(eval(year))
          facets << w.work_facet
        end
      end
    end

    facet_ids = facets.pluck(:id)

    @works = Work.joins(:work_facet).where('work_facets.id in (?)', facet_ids).paginate(page: params[:page], :per_page => 10)
    @search = WorkSearch.new(params[:page])

    render :plain => @works.to_json(:methods => [:thumbnail])
  end

  def load_settings
    @main_owner = @collection.owner
    @owners = ([@main_owner] + @collection.owners).sort_by { |owner| owner.display_name }
    @works_not_in_collection = current_user.owner_works - @collection.works
    @collaborators = @collection.collaborators.sort_by { |collaborator| collaborator.display_name }
    @reviewers = @collection.reviewers.sort_by { |reviewer| reviewer.display_name }
    if User.count > 100
      @nonowners = []
      @noncollaborators = []
      @nonreviewers = []
    else
      @nonowners = User.order(:display_name) - @owners
      @nonowners.each { |user| user.display_name = user.login if user.display_name.empty? }
      @noncollaborators = User.order(:display_name) - @collaborators - @collection.owners
      @nonreviewers = User.order(:display_name) - @reviewers - @collection.owners
    end
  end

  def show
    unless @collection.nil?
      if @collection.restricted
        if !user_signed_in? || !@collection.show_to?(current_user)
          flash[:error] = t('unauthorized_collection', :project => @collection.title)
          redirect_to user_profile_path(@collection.owner)
        end
      end

      if params[:work_search]
        @works = @collection.search_works(params[:work_search]).includes(:work_statistic).paginate(page: params[:page], per_page: 10)
      elsif (params[:works] == 'untranscribed')
        ids = @collection.works.includes(:work_statistic).where.not(work_statistics: {complete: 100}).pluck(:id)
        @works = @collection.works.order_by_incomplete.where(id: ids).paginate(page: params[:page], per_page: 10)
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

        if @collection.metadata_entry?
          description_ids = @collection.works.incomplete_description.pluck(:id)
          ids += description_ids
        end

        works = @collection.works.includes(:work_statistic).where(id: ids).paginate(page: params[:page], per_page: 10)

        if works.empty?
          @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
        else
          @works = works
        end
      else
        @works = @collection.works.includes(:work_statistic).paginate(page: params[:page], per_page: 10)
      end

      if @collection.facets_enabled?
        # construct the search object from the parameters
        @search = WorkSearch.new(params)
        @search.filter([:work, :collection_id]).value=@collection.id
        # the search results are WorkFacets, not works, so we need to fetch the works themselves
        facet_ids = @search.result.pluck(:id)
        @works = @collection.works.joins(:work_facet).where('work_facets.id in (?)', facet_ids).includes(:work_facet).paginate(page: params[:page], :per_page => @per_page) unless params[:search].is_a?(String)

        @date_ranges = []
        date_configs = @collection.facet_configs.where(:input_type => 'date').where.not(:order => nil).order('"order"')
        if date_configs.size > 0
          collection_facets = WorkFacet.joins(:work).where("works.collection_id = #{@collection.id}")
          date_configs.each do |facet_config|
            facet_attr = [:d0,:d1,:d2][facet_config.order]

            selection_values = @works.map{|w| w.work_facet.send(facet_attr)}.reject{|v| v.nil?}
            collection_values = collection_facets.map{|work_facet| work_facet.send(facet_attr)}.reject{|v| v.nil?}

            @date_ranges << {
              :facet => facet_attr,
              :max => collection_values.max.year,
              :min => collection_values.min.year,
              :top => selection_values.max.year,
              :bottom => selection_values.min.year
            }
          end
        end
      end
    else
      redirect_to "/404"
    end
  end

  def add_owner
    unless @user.owner
      @user.owner = true
      @user.account_type = "Staff"
      @user.save!
    end
    @collection.owners << @user
    @user.notification.owner_stats = true
    @user.notification.save!
    if @user.notification.add_as_owner
      send_email(@user, @collection)
    end
    redirect_to collection_edit_owners_path(@collection)
  end

  def remove_owner
    @collection.owners.delete(@user)
    redirect_to collection_edit_owners_path(@collection)
  end

  def add_collaborator
    @user = User.find_by(id: params[:collaborator_id])
    @collection.collaborators << @user
    if @user.notification.add_as_collaborator
      send_email(@user, @collection)
    end
    redirect_to collection_edit_collaborators_path(@collection)
  end

  def remove_collaborator
    @collection.collaborators.delete(@user)
    redirect_to collection_edit_collaborators_path(@collection)
  end

  def add_reviewer
    @collection.reviewers << @user
    if @user.notification.add_as_collaborator
      send_email(@user, @collection)
    end
    redirect_to collection_edit_reviewers_path(@collection)
  end

  def remove_reviewer
    @collection.reviewers.delete(@user)
    redirect_to collection_edit_reviewers_path(@collection)
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

  def toggle_collection_active
    @collection.is_active = !@collection.active?
    @collection.save!

    # Register New Deed for In/Active
    deed = Deed.new
    deed.collection = @collection
    deed.user = current_user
    if @collection.active?
      deed.deed_type = DeedType::COLLECTION_ACTIVE
    else
      deed.deed_type = DeedType::COLLECTION_INACTIVE
    end
    deed.save!

    redirect_to action: 'edit', collection_id: @collection.id
  end

  def toggle_collection_api_access
    @collection.api_access = !@collection.api_access
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def restrict_collection
    @collection.restricted = true
    @collection.save!
    redirect_to action: 'edit', collection_id: @collection.id
  end

  def restrict_transcribed
    @collection.works.joins(:work_statistic).where('work_statistics.complete' => 100, :restrict_scribes => false).update_all(restrict_scribes: true)
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

  def enable_metadata_entry
    @collection.data_entry_type = Collection::DataEntryType::TEXT_AND_METADATA
    @collection.save!
    redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  end

  def disable_metadata_entry
    @collection.data_entry_type = Collection::DataEntryType::TEXT_ONLY
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
    if @collection.field_based && !@collection.transcription_fields.present? 
      flash.now[:info] = t('.alert') 
    end
  end

  def update
    @collection.subjects_disabled = (params[:collection][:subjects_enabled] == "0") #:subjects_enabled is "0" or "1"
    params[:collection].delete(:subjects_enabled)

    @collection.attributes = collection_params

    if collection_params[:slug].blank?
      @collection.slug = @collection.title.parameterize
    end
   
    if @collection.save
      flash[:notice] = t('.notice')
      redirect_to action: 'edit', collection_id: @collection.id
    else
      edit # load the appropriate variables
      render action: 'edit'
    end
  end

  # tested
  def create
    @collection = Collection.new
    @collection.title = params[:collection][:title]
    @collection.intro_block = params[:collection][:intro_block]
    if current_user.account_type != "Staff"
      @collection.owner = current_user
    else
      extant_collection = current_user.collections.detect { |c| c.owner.account_type != "Staff" }
      @collection.owner = extant_collection.owner
      @collection.owners << current_user
    end
    if @collection.save
      flash[:notice] = t('.notice')
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
      :pages_transcribed, 
      :page_edits, 
      :pages_translated, 
      :ocr_corrections,
      :notes, 
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

      id_data = [user.display_name, user.email]
      time_data = [time_total, time_proportional]

      user_deeds = @collection_deeds.select { |d| d.user_id == user.id }

      user_stats = [
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_TRANSCRIPTION },
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_EDIT },
        user_deeds.count { |d| d.deed_type == DeedType::PAGE_TRANSLATED },
        user_deeds.count { |d| d.deed_type == DeedType::OCR_CORRECTED },
        user_deeds.count { |d| d.deed_type == DeedType::NOTE_ADDED }
      ]

      id_data + time_data + user_stats
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

  def activity_download
    start_date = params[:start_date]
    end_date = params[:end_date]

    start_date = start_date.to_datetime.beginning_of_day
    end_date = end_date.to_datetime.end_of_day

    recent_activity = @collection.deeds.where({created_at: start_date...end_date})
        .where(deed_type: DeedType.contributor_types)

    headers = [
      :date,
      :user,
      :user_email,
      :deed_type,
      :page_title,
      :page_url,
      :work_title,
      :work_url,
      :comment,
      :subject_title,
      :subject_url
    ]

    rows = recent_activity.map {|d|

    note = ''
    note += d.note.title if d.deed_type == DeedType::NOTE_ADDED && !d.note.nil?

      record = [
        d.created_at,
        d.user.display_name,
        d.user.email,
        d.deed_type
      ]

      if d.deed_type == DeedType::ARTICLE_EDIT 
        record += ['','','','','',]
        record += [
          d.article ? d.article.title : '[deleted]', 
          d.article ? collection_article_show_url(d.collection.owner, d.collection, d.article) : ''
        ]
      else
        unless d.deed_type == DeedType::COLLECTION_JOINED
          pagedeeds = [
            d.page.title,
            collection_transcribe_page_url(d.page.collection.owner, d.page.collection, d.page.work, d.page),
            d.work.title,
            collection_read_work_url(d.work.collection.owner, d.work.collection, d.work),
            note,
          ]
          record += pagedeeds
          record += ['','']
        end
      end
      record
    }

    csv = CSV.generate(:headers => true) do |records|
      records << headers
      rows.each do |row|
          records << row
      end
    end

    send_data( csv, 
      :filename => "#{start_date.strftime('%Y-%m%b-%d')}-#{end_date.strftime('%Y-%m%b-%d')}_#{@collection.slug}_activity.csv",
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
    @review='transcription'
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).needs_transcription.order(work_id: :asc, position: :asc).paginate(page: params[:page], per_page: 10)
    @count = @pages.count
    @incomplete_pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).needs_completion.order(work_id: :asc, position: :asc).paginate(page: params[:page], per_page: 10)
    @incomplete_count = @incomplete_pages.count
  end

  def needs_review_pages
    work_ids = @collection.works.pluck(:id)
    @review='review'
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).review.paginate(page: params[:page], per_page: 10)
  end

  def start_transcribing
    page = find_untranscribed_page
    if page.nil?
      flash[:notice] = t('.notice')
      redirect_to collection_path(@collection.owner, @collection)
    else
      if !user_signed_in?
        redirect_to collection_guest_page_path(page.collection.owner, page.collection, page.work, page)
      else
        redirect_to collection_transcribe_page_path(page.collection.owner, page.collection, page.work, page)
      end
    end
  end

  def enable_ocr
    @collection.enable_ocr
    flash[:notice] = t('.notice')
    redirect_to edit_collection_path(@collection.owner, @collection)
  end

  def disable_ocr
    @collection.disable_ocr
    flash[:notice] = t('.notice')
    redirect_to edit_collection_path(@collection.owner, @collection)
  end

private
  def authorized?
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def review_authorized?
    unless user_signed_in? && current_user.can_review?(@collection)
      redirect_to new_user_session_path
    end
  end


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

  def collection_params
    params.require(:collection).permit(:title, :slug, :intro_block, :footer_block, :transcription_conventions, :help, :link_help, :subjects_disabled, :subjects_enabled, :review_type, :hide_completed, :text_language, :default_orientation, :voice_recognition, :picture, :user_download)
  end
end
