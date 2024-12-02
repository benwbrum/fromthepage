# handles administrative tasks for the work object
class WorkController < ApplicationController
  # require 'ftools'
  include XmlSourceProcessor

  protect_from_forgery :except => [:set_work_title,
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
    :pages_tab,
    :delete,
    :new,
    :create,
    :edit_scribes,
    :add_scribe,
    :remove_scribe,
    :search_scribes
  ]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, only: [:new, :create, :configurable_printout, :edit_scribes, :remove_scribe]

  def authorized?
    if !user_signed_in? || !current_user.owner
      ajax_redirect_to dashboard_path
    elsif @work && !current_user.like_owner?(@work)
      ajax_redirect_to dashboard_path
    end
  end

  def metadata_overview_monitor
    @is_monitor_view = true
    render :template => "transcribe/monitor_view"
  end

  def configurable_printout
    @bulk_export = BulkExport.new
    @bulk_export.collection = @collection
    @bulk_export.work = @work
    @bulk_export.text_pdf_work = true
    @bulk_export.report_arguments['include_contributors'] = true
    @bulk_export.report_arguments['include_metadata'] = true
    @bulk_export.report_arguments['preserve_linebreaks'] = false
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
    @work.destroy
    redirect_to dashboard_owner_path
  end

  def new
    @work = Work.new
    @collections = current_user.all_owner_collections
  end

  def edit
    @collections = current_user.collections
    # set subjects to true if there are any articles/page_article_links
    @subjects = !@work.articles.blank?
    @scribes = @work.scribes
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
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
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
    redirect_to :action => 'edit', :work_id => @work.id
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
      ajax_redirect_to(work_pages_tab_path(:work_id => @work.id, :anchor => 'create-page'))
    else
      render :new
    end
  end

  def update
    @work = Work.find(params[:id].to_i)
    id = @work.collection_id
    @collection = @work.collection if @collection.nil?
    #check the work transcription convention against the collection version
    #if they're the same, don't update that attribute of the work
    params_convention = params[:work][:transcription_conventions]
    collection_convention = @work.collection.transcription_conventions

    if params_convention == collection_convention
      @work.attributes = work_params.except(:transcription_conventions)
    else
      @work.attributes = work_params
    end

    #if the slug field param is blank, set slug to original candidate
    if work_params[:slug].blank?
      @work.slug = @work.title.parameterize
    end

    if params[:work][:collection_id] != id.to_s
      if @work.save
        change_collection(@work)
        flash[:notice] = t('.work_updated')
        #find new collection to properly redirect
        col = Collection.find_by(id: @work.collection_id)
        redirect_to edit_collection_work_path(col.owner, col, @work)
      else
        @scribes = @work.scribes
        @nonscribes = User.all - @scribes
        @collections = current_user.collections
        #set subjects to true if there are any articles/page_article_links
        @subjects = !@work.articles.blank?
        render :edit
      end
    else
      if @work.save
        flash[:notice] = t('.work_updated')
        redirect_to edit_collection_work_path(@collection.owner, @collection, @work)
      else
        @scribes = @work.scribes
        @nonscribes = User.all - @scribes
        @collections = current_user.collections
        #set subjects to true if there are any articles/page_article_links
        @subjects = !@work.articles.blank?
        render :edit
      end
    end
  end

  def change_collection(work)
    record_deed(work, DeedType::WORK_ADDED, work.owner)
    unless work.articles.blank?
      #delete page_article_links for this work
      page_ids = work.pages.ids
      links = PageArticleLink.where(page_id: page_ids)
      links.destroy_all

      #remove links from pages in this work
      work.pages.each do |p|
        unless p.source_text.nil?
          p.remove_transcription_links(p.source_text)
        end
        unless p.source_translation.nil?
          p.remove_translation_links(p.source_translation)
        end
      end
      work.save!
    end
    work.update_deed_collection
  end

  def revert
    work = Work.find_by(id: params[:work_id])
    work.update_attribute(:transcription_conventions, nil)
    render :plain => work.collection.transcription_conventions
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

  private

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
      document_set_ids: []
    )
  end

end
