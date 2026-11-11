class SubjectHeadingsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
  before_action :load_field
  before_action :require_owner

  # Configure Subject Headings modal: the only place headings are saved.
  def show
    @inventory = @field.subject_heading_inventory
    render layout: false if request.xhr?
  end

  def update
    if params[:file].present?
      SubjectHeadings::Import.new(field: @field, upload: params[:file], instructions: params[:instructions]).call
    else
      raise SubjectHeadings::Import::ImportError, 'Choose a CSV file.' unless @field.subject_heading_inventory
      @field.update!(subject_heading_instructions: params[:instructions])
    end
    flash[:notice] = 'Subject headings saved.'
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  rescue SubjectHeadings::Import::ImportError => e
    @error = e.message
    render_configure_error
  rescue ActiveRecord::RecordInvalid => e
    @error = e.record.errors.full_messages.to_sentence
    render_configure_error
  end

  # Validate Subject Headings modal.
  def new_validation
    render layout: false if request.xhr?
  end

  def create_validation
    validation = SubjectHeadingValidation.start!(field: @field, upload: params[:file], user: current_user)
    if validation.in_progress?
      flash[:info] = "Validation started. Email will be sent to #{ERB::Util.html_escape(current_user.email)} when it is finished."
    else
      flash[:alert] = validation.error_message
    end
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  rescue SubjectHeadings::Import::ImportError => e
    @error = e.message
    render :new_validation, layout: !request.xhr?, status: :unprocessable_entity
  end

  # Review Subject Heading Validation modal.
  def validation
    @validation = @field.subject_heading_validation
    return redirect_to collection_new_subject_headings_validation_path(@collection.owner, @collection, @field) unless @validation
    render layout: false if request.xhr?
  end

  # The field row's validation/configuration buttons, polled while validation runs.
  def buttons
    render partial: 'subject_headings/field_buttons', locals: { field: @field }
  end

  def template
    send_data "heading,uri\r\nAbolitionists,\r\nAfrican American farmers,\r\nAgriculture,\r\n", type: 'text/csv; charset=utf-8', filename: 'subject_headings_template.csv'
  end

  def report
    validation = @field.subject_heading_validation
    return head :not_found unless validation&.report_csv.present?

    response.headers['Cache-Control'] = 'private, no-store'
    filename = "#{File.basename(validation.filename, '.*')}_validation.csv"
    send_data validation.report_csv, type: 'text/csv; charset=utf-8', filename: filename
  end

  def retry_validation
    validation = @field.subject_heading_validation
    return head :conflict unless validation&.retryable? && validation.queue!(user: current_user)

    flash[:info] = "Retrying lookup errors. Email will be sent to #{ERB::Util.html_escape(current_user.email)} when it is finished."
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  end

  private

  def render_configure_error
    @inventory = @field.reload.subject_heading_inventory
    render :show, layout: !request.xhr?, status: :unprocessable_entity
  end

  def load_field
    raise ActiveRecord::RecordNotFound unless @collection
    @field = @collection.metadata_fields.find(params[:field_id])
    head :not_found unless @field.subject_headings?
  end

  def require_owner
    head :forbidden unless user_signed_in? && (current_user.admin? || current_user.like_owner?(@collection))
  end
end
