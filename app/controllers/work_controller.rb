class WorkController < ApplicationController
  # require 'ftools'
  include ApplicationHelper
  include XmlSourceProcessor

  protect_from_forgery except: [:set_work_title,
                                   :set_work_description,
                                   :set_work_physical_description,
                                   :set_work_document_history,
                                   :set_work_permission_description,
                                   :set_work_location_of_composition,
                                   :set_work_author,
                                   :set_work_transcription_conventions]
  # tested
  before_action :authorized?, only: [
    :edit,
    :edit_tasks,
    :edit_metadata,
    :edit_privacy,
    :edit_danger,
    :pages_tab,
    :delete,
    :new,
    :create,
    :update,
    :edit_scribes,
    :add_scribe,
    :remove_scribe,
    :search_scribes
  ]

  # no layout if xhr request
  layout :dynamic_layout, only: [:new, :create, :configurable_printout, :edit_scribes, :remove_scribe]

  def metadata_overview_monitor
    @is_monitor_view = true
    render template: 'transcribe/monitor_view'
  end

  def configurable_printout
    @bulk_export = BulkExport.new
    @bulk_export.collection = @collection
    @bulk_export.work = @work
    @bulk_export.text_pdf_work = true
    @bulk_export.report_arguments['include_contributors'] = true
    @bulk_export.report_arguments['include_metadata'] = true
    @bulk_export.report_arguments['include_notes'] = true
    @bulk_export.report_arguments['preserve_linebreaks'] = false
  end

  def search
    @search_string = search_params[:term]

    @es_query = Elasticsearch::MultiQuery.new(
      query: @search_string,
      query_params: {
        mode: 'work',
        slug: @work.slug
      },
      page: params[:page] || 1,
      scope: search_params[:filter],
      user: current_user
    ).call

    @breadcrumb_scope = { work: true }
    @work_filter = @es_query.work_filter

    @search_results = @es_query.results
    @full_count = @es_query.total_count
    @type_counts = @es_query.type_counts
  end

  def describe
    @layout_mode = cookies[:transcribe_layout_mode] || @collection.default_orientation
    @metadata_array = JSON.parse(@work.metadata_description || '[]')
  end

  def needs_review_checkbox_checked
    params[:work] && params[:work]['needs_review'] == '1'
  end

  def save_description
    @field_cells = request.params[:fields]
    @metadata_array = @work.process_fields(@field_cells)
    @layout_mode = cookies[:transcribe_layout_mode] || @collection.default_orientation

    if params['save_to_incomplete'] && !needs_review_checkbox_checked
      @work.description_status = Work::DescriptionStatus::INCOMPLETE
    elsif params['save_to_needs_review'] || needs_review_checkbox_checked
      @work.description_status = Work::DescriptionStatus::NEEDS_REVIEW
    elsif (params['save_to_transcribed'] && !needs_review_checkbox_checked) || params['approve_to_transcribed']
      @work.description_status = Work::DescriptionStatus::DESCRIBED
    else
      # unexpected state
    end

    if @work.save
      # TODO record_description_deed(@work)
      if @work.saved_change_to_description_status?
        record_deed(@work, DeedType::DESCRIBED_METADATA, current_user)
      else
        record_deed(@work, DeedType::EDITED_METADATA, current_user)
      end

      flash[:notice] = t('.work_described')
      render :describe
    else
      render :describe
    end
  end

  def description_versions
    # @selected_version = @page_version.present? ? @page_version : @page.page_versions.first
    # @previous_version = params[:compare_version_id] ? PageVersion.find(params[:compare_version_id]) : @selected_version.prev
    selected_version_id = params[:metadata_description_version_id]
    if selected_version_id
      @selected_version= MetadataDescriptionVersion.find(selected_version_id)
    else
      @selected_version= @work.metadata_description_versions.first
    end
    # NB: Unlike in page versions (which are created when we first create the page), metadata description versions may be nil
    compare_version_id = params[:compare_version_id]
    if compare_version_id
      @previous_version = MetadataDescriptionVersion.find(compare_version_id)
    else
      if @selected_version.version_number > 1
        @previous_version = @work.metadata_description_versions.second
      else
        @previous_version = @selected_version
      end
    end
    # again, both may be blank here
  end

  def delete
    @result = Work::Delete.new(
      work: @work,
      user: current_user
    ).call

    respond_to(&:turbo_stream)
  end

  def edit
    @collections = current_user.collections
    @document_sets = @work.collection.document_sets
    @subjects_exist = @work.articles.any?

    @document_sets_options = @document_sets.map { |ds| [ds.title, ds.id] }
  end

  def edit_tasks
  end

  def edit_metadata
  end

  def edit_privacy
    @scribes = @work.scribes
  end

  def edit_ai
    calculate_counts
  end

  def edit_danger
  end

  def edit_scribes
    @scribes = @work.scribes
    @nonscribes = User.where.not(id: @scribes.pluck(:id)).limit(100)
  end

  def search_scribes
    query = "%#{params[:term].to_s.downcase}%"
    excluded_ids = @work.scribes.pluck(:id) + [@work.owner.id]
    users = User.where('LOWER(real_name) LIKE :search OR LOWER(email) LIKE :search', search: query)
                .where.not(id: excluded_ids)
                .limit(100)

    render json: { results: users.map { |u| { text: "#{u.display_name} #{u.email}", id: u.id } } }
  end

  def add_scribe
    scribe = User.find_by(id: params[:scribe_id])
    @work.scribes << scribe

    if scribe.notification.add_as_collaborator && SMTP_ENABLED
      begin
        UserMailer.work_collaborator(scribe, @work).deliver!
      # :nocov:
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
      # :cov:
    end

    redirect_to work_edit_scribes_path(@collection, @work)
  end

  def remove_scribe
    scribe = User.find_by(id: params[:scribe_id])
    @work.scribes.delete(scribe)

    redirect_to work_edit_scribes_path(@collection, @work)
  end

  def update_work
    @work.update(work_params)
    redirect_to work_edit_path(work_id: @work.id)
  end

  # tested
  def create
    @work = Work.new
    @work.title = params[:work][:title]
    @work.collection_id = params[:work][:collection_id]
    @work.description = params[:work][:description]
    @work.owner = current_user
    @collections = current_user.all_owner_collections

    if @work.save
      record_deed(@work, DeedType::WORK_ADDED, work.owner)
      flash[:notice] = t('.work_created')
      ajax_redirect_to(work_pages_tab_path(work_id: @work.id, anchor: 'create-page'))
    else
      render :new
    end
  end

  def update
    work = Work.find(params[:id])
    @collection ||= work.collection

    @result = Work::Update.new(work: work, work_params: work_params).call

    @work = @result.work

    if @result.success? && @result.original_collection_id != @result.collection.id
      record_deed(@work, DeedType::WORK_ADDED, @work.owner)
      @collection = @work.collection
    end

    respond_to do |format|
      template = case params[:scope]
      when 'edit_tasks'
        'work/update_tasks'
      when 'edit_metadata'
        'work/update_metadata'
      when 'edit_privacy'
        @scribes = @work.scribes
        'work/update_privacy'
      else
        @collections = current_user.collections
        @document_sets = @collection.document_sets
        @subjects_exist = @work.articles.any?

        @document_sets_options = @document_sets.map { |ds| [ds.title, ds.id] }
        'work/update_general'
      end

      format.turbo_stream { render template }
    end
  end

  def update_featured_page
    @work.update(featured_page: params[:page_id])
    redirect_back fallback_location: @work
  end

  def document_sets_select
    document_sets = current_user.document_sets.where(collection_id: params[:collection_id])

    render partial: 'document_sets_select', locals: { document_sets: document_sets }
  end

  protected

  def record_deed(work, deed_type, user)
    deed = Deed.new
    deed.work = work
    deed.deed_type = deed_type
    deed.collection = work.collection
    deed.user = user
    deed.save!
    update_search_attempt_contributions
  end

  def show
    # Set meta information for work pages for better archival
    @page_title = "#{@work.title} - #{@collection.title}"
    @meta_description = "Historical document: #{@work.title}#{@work.author.present? ? " by #{@work.author}" : ""} in the #{@collection.title} collection. #{@work.description}".truncate(160)
    @meta_keywords = [@work.title, @work.author, @collection.title, 'historical document', 'digital archive'].compact.join(', ')

    # Generate structured data for work
    @structured_data = {
      '@context' => 'https://schema.org',
      '@type' => 'DigitalDocument',
      'name' => @work.title,
      'description' => @work.description,
      'inLanguage' => @collection.text_language || 'en',
      'isPartOf' => {
        '@type' => 'Collection',
        'name' => @collection.title,
        'description' => to_snippet(@collection.intro_block)
      },
      'url' => request.original_url,
      'dateModified' => @work.most_recent_deed_created_at&.iso8601,
      'publisher' => {
        '@type' => 'Organization',
        'name' => @collection.owner&.display_name || 'FromThePage'
      }
    }

    # Add optional fields conditionally
    @structured_data['author'] = @work.author if @work.author.present?
    @structured_data['dateCreated'] = @work.document_date if @work.document_date.present?

    # Add archival-friendly headers
    respond_to do |format|
      format.html do
        response.headers['X-Robots-Tag'] = 'index, follow, archive'
      end
    end
  end

  public

  def split_page
    unless user_signed_in? && current_user.can_transcribe?(@work, @collection)
      redirect_to dashboard_path, alert: t('work.split_page.unauthorized')
      return
    end

    page = @work.pages.find(params[:page_id])
    new_work_title = params[:new_work_title].presence || default_split_title

    pages_to_move = @work.pages.where('position < ?', page.position).order(:position).to_a

    if pages_to_move.empty?
      redirect_to collection_transcribe_page_path(@collection.owner, @collection, @work, page),
        alert: t('work.split_page.no_previous_pages')
      return
    end

    new_work = Work.new(
      title: new_work_title,
      collection_id: @work.collection_id,
      owner_user_id: @work.owner_user_id,
      supports_translation: @work.supports_translation,
      restrict_scribes: @work.restrict_scribes,
      scribes_can_edit_titles: @work.scribes_can_edit_titles,
      pages_are_meaningful: @work.pages_are_meaningful
    )

    unless new_work.save
      redirect_to collection_transcribe_page_path(@collection.owner, @collection, @work, page),
        alert: t('work.split_page.create_failed', errors: new_work.errors.full_messages.join(', '))
      return
    end

    pages_to_move.each_with_index do |p, idx|
      p.update_columns(work_id: new_work.id, position: idx + 1)
    end

    @work.pages.reload.order(:position).each_with_index do |p, idx|
      p.update_column(:position, idx + 1)
    end

    page.update_column(:is_first_page_candidate, false)

    new_work.update_statistic
    @work.update_statistic

    if params[:edit_metadata_after_split].present? && current_user.like_owner?(@work)
      redirect_to edit_metadata_collection_work_path(@collection.owner, @collection, new_work)
      return
    end

    @split_page     = page
    @new_work       = new_work
    @new_work_title = new_work_title
    @split_count    = pages_to_move.count
    render :split_page
  end

  def dismiss_segmentation
    unless user_signed_in? && current_user.can_transcribe?(@work, @collection)
      head :forbidden
      return
    end

    page = @work.pages.find(params[:page_id])
    page.update_column(:is_first_page_candidate, false)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("segmentation-banner-#{page.id}") }
      format.html { redirect_back fallback_location: collection_transcribe_page_path(@collection.owner, @collection, @work, page) }
    end
  end

  private

  def authorized?
    if !user_signed_in? || !current_user.owner
      ajax_redirect_to dashboard_path
    elsif @work && !current_user.like_owner?(@work)
      ajax_redirect_to dashboard_path
    end
  end

  def default_split_title
    first_page = @work.pages.order(:position).first
    if first_page&.title.present? &&
       first_page.title !~ /\A(Untitled Page )?\d+\z/ &&
       first_page.title != @work.title
      return first_page.title
    end
    base = @work.title
    existing_count = @work.collection.works.where('title LIKE ?', "#{ActiveRecord::Base.sanitize_sql_like(base)} %").count
    "#{base} #{existing_count + 1}"
  end

  def search_params
    params.permit(:term, :page, :filter, :work_id, :collection_id, :user_id)
  end

  def work_params
    params.require(:work).permit(
      :title,
      :description,
      :collection_id,
      :supports_translation,
      :slug,
      :ocr_correction,
      :transcription_conventions,
      :author,
      :recipient,
      :location_of_composition,
      :identifier,
      :pages_are_meaningful,
      :physical_description,
      :document_history,
      :permission_description,
      :translation_instructions,
      :scribes_can_edit_titles,
      :restrict_scribes,
      :picture,
      :genre,
      :source_location,
      :source_collection_name,
      :source_box_folder,
      :in_scope,
      :editorial_notes,
      :document_date,
      :term,
      document_set_ids: []
    )
  end

  def dynamic_layout
    request.xhr? ? false : 'application'
  end
end
