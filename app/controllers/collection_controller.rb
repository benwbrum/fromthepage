# handles administrative tasks for the collection object
class CollectionController < ApplicationController

  include ContributorHelper
  include AddWorkHelper
  include CollectionHelper

  public :render_to_string

  protect_from_forgery :except => [:set_collection_title,
                                   :set_collection_intro_block,
                                   :set_collection_footer_block]

  edit_actions = [:edit, :edit_tasks, :edit_look, :edit_privacy, :edit_help, :edit_quality_control, :edit_danger]

  before_action :authorized?, only: [
    :new,
    :edit,
    :update,
    :delete,
    :create,
    :edit_owner,
    :remove_owner,
    :add_owner,
    :edit_collaborators,
    :remove_collaborator,
    :add_collaborator,
    :edit_reviewers,
    :remove_reviewer,
    :add_reviewer,
    :new_mobile_user,
    :search_users
  ]
  before_action :review_authorized?, :only => [:reviewer_dashboard, :works_to_review, :one_off_list, :recent_contributor_list, :user_contribution_list]
  before_action :set_collection, :only => edit_actions + [:show, :update, :contributors, :new_work, :works_list, :needs_transcription_pages, :needs_review_pages, :start_transcribing]
  before_action :load_settings, :only => edit_actions + [ :update, :upload, :edit_owners, :block_users, :remove_owner, :edit_collaborators, :remove_collaborator, :edit_reviewers, :remove_reviewer]
  before_action :permit_only_transcribed_works_flag, only: [:works_list]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:new, :create, :edit_buttons, :edit_owners, :remove_owner, :add_owner, :edit_collaborators, :remove_collaborator, :add_collaborator, :edit_reviewers, :remove_reviewer, :add_reviewer, :new_mobile_user]

  def authorized?
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

  def search_users
    query = "%#{params[:term].to_s.downcase}%"
    excluded_ids = @collection.collaborators.pluck(:id) + [@collection.owner.id]
    users = User.where('LOWER(real_name) LIKE :search OR LOWER(email) LIKE :search', search: query)
                .where.not(id: excluded_ids)
                .limit(100)

    render json: { results: users.map { |u| { text: "#{u.display_name} #{u.email}", id: u.id } } }
  end

  def reviewer_dashboard
    # works which have at least one page needing review
    @total_pages=@collection.pages.count
    @pages_needing_review=@collection.pages.where(status: :needs_review).count
    @transcribed_pages=@collection.pages.where(status: Page::NOT_INCOMPLETE_STATUSES).count
    @works_to_review = @collection.pages.where(status: :needs_review).pluck(:work_id).uniq.count
  end

  def works_to_review
    @works = @collection.works.joins(:work_statistic).includes(:notes, :pages).where.not('work_statistics.needs_review' => 0).reorder("works.title")
                        .paginate(:page => params[:page], :per_page => 15)
  end

  def one_off_list
    @pages = @collection.pages_needing_review_for_one_off
  end

  def recent_contributor_list
    @unreviewed_users = @collection.never_reviewed_users
  end

  def user_contribution_list
    unless params[:quality_sampling_id].blank?
      @quality_sampling = QualitySampling.find(params[:quality_sampling_id])
    end
    @pages = @collection.pages.where(status: :needs_review).where(:last_editor_user_id => @user.id)
  end

  def approve_all
    @quality_sampling = QualitySampling.find(params[:quality_sampling_id])
    @pages = @collection.pages.where(status: :needs_review).where(:last_editor_user_id => @user.id)
    page_count = @pages.count
    @pages.update_all(status: :transcribed)
    @collection.works.each do |work|
      work.work_statistic.recalculate({ type: Page.statuses[:needs_review] }) if work.work_statistic
    end
    flash[:notice] = t('.approved_n_pages', page_count: page_count)
    redirect_to(collection_quality_sampling_path(@collection.owner, @collection, @quality_sampling))
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

    flash[:notice] = t('.editor_buttons_updated')
    ajax_redirect_to(edit_tasks_collection_path(@collection.owner, @collection))

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

  def new_mobile_user
    # don't show popup again
    session[:new_mobile_user] = false
  end


  def show
    if current_user && CollectionBlock.find_by(collection_id: @collection.id, user_id: current_user.id).present?
      flash[:error] = t('unauthorized_collection', :project => @collection.title)
      redirect_to user_profile_path(@collection.owner)
    else
      if @collection.alphabetize_works
        order_clause = 'works.title ASC'
      else
        order_clause = 'work_statistics.complete ASC, work_statistics.transcribed_percentage ASC, work_statistics.needs_review_percentage DESC'
      end

      @new_mobile_user = !!(session[:new_mobile_user])
      unless @collection.nil?
        if @collection.restricted
          if !user_signed_in? || !@collection.show_to?(current_user)
            flash[:error] = t('unauthorized_collection', :project => @collection.title)
            redirect_to user_profile_path(@collection.owner)
          end
        end

        # Coming from work title/metadata search
        if params[:search_attempt_id]
          @search_attempt = SearchAttempt.find_by(id: params[:search_attempt_id])
          if session[:search_attempt_id] != @search_attempt.id
            session[:search_attempt_id] = @search_attempt.id
          end
          @works = @search_attempt.results.paginate(page: params[:page], per_page: 10)

        elsif (params[:works] == 'untranscribed')
          ids = @collection.works.includes(:work_statistic).where.not(work_statistics: {complete: 100}).pluck(:id)
          @works = @collection.works.order_by_incomplete.where(id: ids).paginate(page: params[:page], per_page: 10)
          #show all works
        elsif (params[:works] == 'show')
          @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
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

          works = @collection.works.joins(:work_statistic).where(id: ids).reorder(order_clause).paginate(page: params[:page], per_page: 10)

          if works.empty?
            @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
          else
            @works = works
          end
        else
          @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
        end

        if @collection.facets_enabled?
          # construct the search object from the parameters
          @search = WorkSearch.new(params)
          @search.filter([:work, :collection_id]).value=@collection.id
          # the search results are WorkFacets, not works, so we need to fetch the works themselves
          facet_ids = @search.result.pluck(:id)
          @works = @collection.works.joins(:work_facet).where('work_facets.id in (?)', facet_ids).includes(:work_facet).paginate(page: params[:page], :per_page => @per_page) unless params[:search].is_a?(String)

          @date_ranges = []
          date_configs = @collection.facet_configs.where(input_type: 'date').where.not(order: nil).order(order: :asc)
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

          if params[:search_attempt_id]
            @search_attempt = SearchAttempt.find_by(id: params[:search_attempt_id])
            if session[:search_attempt_id] != @search_attempt.id
              session[:search_attempt_id] = @search_attempt.id
            end
            @works = @search_attempt.results.paginate(page: params[:page], per_page: 10)
          elsif (params[:works] == 'untranscribed')
            ids = @collection.works.includes(:work_statistic).where.not(work_statistics: {complete: 100}).pluck(:id)
            @works = @collection.works.order_by_incomplete.where(id: ids).paginate(page: params[:page], per_page: 10)
            #show all works
          elsif (params[:works] == 'show')
            @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
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

            works = @collection.works.joins(:work_statistic).where(id: ids).reorder(order_clause).paginate(page: params[:page], per_page: 10)

            if works.empty?
              @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
            else
              @works = works
            end
          else
            @works = @collection.works.joins(:work_statistic).reorder(order_clause).paginate(page: params[:page], per_page: 10)
          end

          if @collection.facets_enabled?
            # construct the search object from the parameters
            @search = WorkSearch.new(params)
            @search.filter([:work, :collection_id]).value=@collection.id
            # the search results are WorkFacets, not works, so we need to fetch the works themselves
            facet_ids = @search.result.pluck(:id)
            @works = @collection.works.joins(:work_facet).where('work_facets.id in (?)', facet_ids).includes(:work_facet).paginate(page: params[:page], :per_page => @per_page) unless params[:search].is_a?(String)

            @date_ranges = []
            date_configs = @collection.facet_configs.where(input_type: 'date').where.not(order: nil).order(order: :asc)
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
        end
      else
        redirect_to "/404"
      end
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

  def remove_block_user
    collection_block = CollectionBlock.find_by(collection_id: @collection.id, user_id: @user.id)
    collection_block.destroy if collection_block
    redirect_to collection_block_users_path(@collection)
  end

  def block_users
    @list_of_blocked_users = @collection.blocked_users
    render layout: false
  end

  def add_collaborator
    collaborator = User.find_by(id: params[:collaborator_id])
    @collection.collaborators << collaborator
    send_email(collaborator, @collection) if collaborator.notification.add_as_collaborator

    redirect_to collection_edit_collaborators_path(@collection)
  end

  def remove_collaborator
    collaborator = User.find_by(id: params[:collaborator_id])
    @collection.collaborators.delete(collaborator)

    redirect_to collection_edit_collaborators_path(@collection)
  end

  def add_reviewer
    @collection.reviewers << @user
    if @user.notification.add_as_collaborator
      send_email(@user, @collection)
    end
    redirect_to collection_edit_reviewers_path(@collection)
  end

  def add_block_user
    CollectionBlock.create(collection_id: @collection.id, user_id: @user.id)
    redirect_to collection_block_users_path(@collection)
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
    redirect_back fallback_location: edit_privacy_collection_path(@collection.owner, @collection)
  end

  def toggle_collection_active(is_active)
    # Register New Deed for In/Active
    deed = Deed.new
    deed.collection = @collection
    deed.user = current_user
    if is_active
      deed.deed_type = DeedType::COLLECTION_ACTIVE
    else
      deed.deed_type = DeedType::COLLECTION_INACTIVE
    end
    deed.save!
  end

  def restrict_collection
    @collection.restricted = true
    @collection.save!
    redirect_back fallback_location: edit_privacy_collection_path(@collection.owner, @collection)
  end

  def restrict_transcribed
    @collection.works.joins(:work_statistic).where('work_statistics.complete' => 100, :restrict_scribes => false).update_all(restrict_scribes: true)
    redirect_back fallback_location: edit_privacy_collection_path(@collection.owner, @collection)
  end

  def enable_fields
    @collection.field_based = true
    @collection.voice_recognition = false
    @collection.language = nil
    @collection.save!
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def delete
    @collection.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @collection = Collection.new
  end

  def edit
  end

  def edit_tasks
    @text_languages = ISO_639::ISO_639_2.map {|lang| [lang[3], lang[0]]}
    if @collection.field_based && !@collection.transcription_fields.present?
      flash.now[:info] = t('.alert')
    end
  end

  def edit_look
    @ssl = Rails.env.production? ? Rails.application.config.force_ssl : true
  end

  def update
    # Convert incoming params to fit the model
    if collection_params[:subjects_enabled].present?
      params[:collection][:subjects_disabled] = (collection_params[:subjects_enabled] == '1') ? false : true
      params[:collection].delete(:subjects_enabled)
    end
    if collection_params[:data_entry_type].present?
      params[:collection][:data_entry_type] = (collection_params[:data_entry_type] == '1') ? Collection::DataEntryType::TEXT_AND_METADATA : Collection::DataEntryType::TEXT_ONLY
    end

    # Default slug to title if blank
    if collection_params[:slug] == ""
      params[:collection][:slug] = @collection.title.parameterize
    end

    # Call methods to enable/disable features if the fields have changed
    if collection_params[:messageboards_enabled].present? && collection_params[:messageboards_enabled] != @collection.messageboards_enabled
      collection_params[:messageboards_enabled] ? @collection.enable_messageboards : @collection.disable_messageboards
    end
    if collection_params[:is_active].present? && collection_params[:is_active] != @collection.is_active
      toggle_collection_active(collection_params[:is_active] == "true")
    end
    if collection_params[:field_based] == "1" && !@collection.field_based
      enable_fields
    end

    @collection.attributes = collection_params
    updated_fields = updated_fields_hash
    @collection.tags = Tag.where(id: params[:collection][:tags])

    if @collection.save
      if request.xhr?
        render json: {
          success: true,
          updated_field: updated_fields
        }
      else
        flash[:notice] = t('.notice')
        redirect_back fallback_location: edit_collection_path(@collection.owner, @collection)
      end
    else
      if request.xhr?
        render json: {
          success: false,
          errors: @collection.errors.full_messages
        }
      else
        edit # load the appropriate variables
        edit_action = Rails.application.routes.recognize_path(request.referrer)[:action]
        render action: edit_action
      end
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


  def blank_collection
    collection = Collection.find_by(id: params[:collection_id])
    collection.blank_out_collection
    redirect_to action: 'show', collection_id: params[:collection_id]
  end

  def works_list
    if params[:only_transcribed].present?
      @works = @collection.works.joins(:work_statistic).where("work_statistics.transcribed_percentage < ?", 100).where("work_statistics.needs_review = ?", 0).order(:title)
    else
      @works = @collection.works.includes(:work_statistic).order(:title)
    end
  end

  def needs_transcription_pages
    work_ids = @collection.works.pluck(:id)
    @review='transcription'
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).needs_transcription.order(work_id: :asc, position: :asc).paginate(page: params[:page], per_page: 10)
    @count = @pages.count
    @incomplete_pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).needs_completion.order(work_id: :asc, position: :asc).paginate(page: params[:page], per_page: 10)
    @incomplete_count = @incomplete_pages.count
    @heading = t('.pages_need_transcription')
  end

  def needs_review_pages
    work_ids = @collection.works.pluck(:id)
    @review='review'
    @pages = Page.where(work_id: work_ids).joins(:work).merge(Work.unrestricted).review.paginate(page: params[:page], per_page: 10)
    @heading = t('.pages_need_review')
  end

  def needs_metadata_works
    if params['need_review']
      @works = @collection.works.where(description_status: "needsreview")
    else
      @works = @collection.works.where(description_status: ["incomplete", "undescribed"])
    end
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
    redirect_back fallback_location: edit_tasks_collection_path(@collection.owner, @collection)
  end

  def disable_ocr
    @collection.disable_ocr
    flash[:notice] = t('.notice')
    redirect_back fallback_location: edit_tasks_collection_path(@collection.owner, @collection)
  end

  def email_link
    if SMTP_ENABLED
      begin
        UserMailer.new_mobile_user(current_user, @collection).deliver!
      rescue StandardError => e
        log_smtp_error(e, current_user)
      end
    end
    flash[:notice] = "Email sent."
    ajax_redirect_to(collection_path(@collection.owner, @collection))
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

  def updated_fields_hash
    @collection.changed.to_h {|field| [field, @collection.send(field)]}
  end

  def collection_params
    params.require(:collection).permit(
      :title,
      :slug,
      :intro_block,
      :transcription_conventions,
      :help,
      :link_help,
      :subjects_disabled,
      :subjects_enabled,
      :review_type,
      :hide_completed,
      :text_language,
      :default_orientation,
      :voice_recognition,
      :picture,
      :user_download,
      :enable_spellcheck,
      :messageboards_enabled,
      :facets_enabled,
      :supports_document_sets,
      :api_access,
      :data_entry_type,
      :field_based,
      :is_active,
      :search_attempt_id,
      :alphabetize_works,
      :tags
    )
  end

  def load_settings
    @main_owner = @collection.owner
    @owners = ([@main_owner] + @collection.owners).sort_by(&:display_name)
    @works_not_in_collection = current_user.owner_works - @collection.works
    @collaborators = @collection.collaborators
    @reviewers = @collection.reviewers
    @blocked_users = @collection.blocked_users.sort_by(&:display_name)

    collection_owner_ids = @owners.pluck(:id)
    @nonowners = User.where.not(id: collection_owner_ids).order(:display_name).limit(100)
    @noncollaborators = User.where.not(id: @collaborators.pluck(:id) + collection_owner_ids).order(:display_name).limit(100)
    @nonreviewers = User.where.not(id: @reviewers.pluck(:id) + collection_owner_ids).order(:display_name).limit(100)

    @collaborators = @collaborators.sort_by(&:display_name)
    @reviewers = @reviewers.sort_by(&:display_name)
  end

  private

  def permit_only_transcribed_works_flag
    params.permit(:only_transcribed)
  end

end
