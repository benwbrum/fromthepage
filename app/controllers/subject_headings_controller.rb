class SubjectHeadingsController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: -> { head :not_found }
  before_action :load_field
  before_action :require_owner

  def show
    @inventory = @field.subject_heading_inventory
    render layout: false if request.xhr?
  end

  def update
    if params[:file].present?
      inventory = SubjectHeadings::Import.new(field: @field, upload: params[:file], instructions: params[:instructions]).call
      inventory.queue_validation!(user: current_user) if params[:validate_authorities] == '1'
    else
      raise SubjectHeadings::Import::ImportError, 'Choose a CSV file.' unless @field.subject_heading_inventory
      @field.update!(subject_heading_instructions: params[:instructions])
    end
    redirect_to collection_subject_headings_path(@collection.owner, @collection, @field), notice: 'Subject headings saved.'
  rescue SubjectHeadings::Import::ImportError => e
    @inventory = @field.reload.subject_heading_inventory
    @error = e.message
    render :show, layout: !request.xhr?, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    @inventory = @field.reload.subject_heading_inventory
    @error = e.record.errors.full_messages.to_sentence
    render :show, layout: !request.xhr?, status: :unprocessable_entity
  end

  def template
    send_data "heading,uri\r\nAbolitionists,\r\nAfrican American farmers,\r\nAgriculture,\r\n", type: 'text/csv; charset=utf-8', filename: 'subject_headings_template.csv'
  end

  def report
    inventory = @field.subject_heading_inventory
    return head :not_found unless inventory&.report_csv.present?

    response.headers['Cache-Control'] = 'private, no-store'
    send_data inventory.report_csv, type: 'text/csv; charset=utf-8', filename: 'subject_heading_validation.csv'
  end

  def retry_validation
    inventory = @field.subject_heading_inventory
    return head :conflict unless inventory&.validation_retryable?

    return head :conflict unless inventory.queue_validation!(user: current_user)
    redirect_to collection_subject_headings_path(@collection.owner, @collection, @field)
  end

  private

  def load_field
    raise ActiveRecord::RecordNotFound unless @collection
    @field = @collection.metadata_fields.find(params[:field_id])
    head :not_found unless @field.subject_headings?
  end

  def require_owner
    head :forbidden unless user_signed_in? && (current_user.admin? || current_user.like_owner?(@collection))
  end
end
