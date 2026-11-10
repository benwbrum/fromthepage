class TranscriptionFieldController < ApplicationController
  include ActiveModel::Validations

  enforce_permission_checks

  # Loads @transcription_field / @collection before any action runs, so each action can
  # call require_permission on its first line. line_form has no record.
  before_action :load_permission_context, except: [:line_form]

  def multiselect_form
    require_permission(:collection_owner, @collection)
  end

  def save_multiselect
    require_permission(:collection_owner, @collection)

    transcription_field = require_transcription_field
    transcription_field.options = params[:options]
    transcription_field.save!
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  end

  def delete
    require_permission(:collection_owner, @collection)

    field = require_transcription_field
    field.remove_from_list
    field.destroy
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def edit_fields
    require_permission(:collection_owner, @collection)

    @current_fields = @collection.transcription_fields.order(:line_number).order(:position)
    @field_presenter = TranscriptionField::Lib::Presenter.new(view_context: view_context, collection: @collection, edit_action: true)
  end

  def edit_metadata_fields
    require_permission(:collection_owner, @collection)

    @current_fields = @collection.metadata_fields.order(:line_number).order(:position)
    @field_preview = {}
  end

  def add_fields
    require_permission(:collection_owner, @collection)

    if params[:description_instructions]
      @collection.update(description_instructions: params[:description_instructions])
    end
    if params[:data_entry_type]
      @collection.update(data_entry_type: params[:data_entry_type])
    end

    field_type = params[:field_type]
    new_fields = params[:transcription_fields]


    new_fields.each_with_index do |fields, index|
      if fields[:line_number] == 'new'
        fields[:line_number] = new_fields[index-1][:line_number]
      end
      # ignore blank fields
      unless fields[:line_number].blank? || fields[:label].blank?
        if fields[:options].blank?
          fields[:options] = nil
          if fields[:input_type] == 'select'
            fields[:input_type] = 'text'
            errors.add(:base, t('.must_have_options_list'))
          end
        else
          fields[:options].gsub!(/;\s/, ';')
        end
        if fields[:id].blank?
          # if the field doesn't exist, create a new one
          transcription_field = collection_fields.new(transcription_field_params(fields))
          transcription_field.starting_rows = 1
          transcription_field.field_type = field_type
          transcription_field.save
        else
          # otherwise update field if anything changed
          transcription_field = collection_fields.find(fields[:id])
          transcription_field.label = fields[:label]
          transcription_field.input_type = fields[:input_type]
          transcription_field.options = fields[:options] if fields[:input_type] == 'select'
          transcription_field.line_number = fields[:line_number]
          transcription_field.page_number = fields[:page_number]
          transcription_field.percentage = fields[:percentage]
          transcription_field.save
        end
      end
    end
    if errors[:base].any?
      flash[:error] = errors[:base].uniq.join(' ')
    end
    if params[:done].nil?
      if field_type == TranscriptionField::FieldType::TRANSCRIPTION
        redirect_to collection_edit_fields_path(@collection.owner, @collection)
      else
        redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
      end
    else
      redirect_to edit_tasks_collection_path(@collection.owner, @collection)
    end
  end

  # reordering functions
  def reorder_fields
    require_permission(:collection_owner, @collection)

    fields = collection_fields
    Array(params[:field]).each_with_index do |id, index|
      fields.where(id: id).update_all(position: index + 1, line_number: params[:line])
    end
    head :ok
  end

  def line_form
    # Renders an empty form row. It reads no record and changes nothing.
    require_permission(:signed_in)

    @line_count = params[:line_count].strip.next
    @count = @line_count.split(' ').last.to_i
    @field_type = params[:field_type]
    respond_to do |format|
      format.js
    end
  end

  # Spreadsheet column actions
  def column_form
    require_permission(:collection_owner, @collection)

    @line_count = 1
    @count = 1
    require_transcription_field
    respond_to do |format|
      format.js
    end
  end

  def edit_columns
    require_permission(:collection_owner, @collection)

    @current_columns = require_transcription_field.spreadsheet_columns.order(:position)
  end

  def add_columns
    require_permission(:collection_owner, @collection)

    require_transcription_field
    if params[:starting_rows].blank?
      errors.add(:base, t('.starting_rows_must_not_be_blank'))
    else
      @transcription_field.update(starting_rows: params[:starting_rows].to_i)
    end

    new_columns = spreadsheet_column_params[:spreadsheet_columns]

    new_columns.each_with_index do |column, index|
      # ignore blank fields
      unless column[:label].blank?
        if column[:options].blank?
          column[:options] = nil
          if column[:input_type] == 'select'
            column[:input_type] = 'text'
            errors.add(:base, t('.must_have_options_list'))
          end
        else
          column[:options].gsub!(/;\s/, ';')
        end

        if column[:id].blank?
          # if the field doesn't exist, create a new one
          spreadsheet_column = @transcription_field.spreadsheet_columns.new(column.except(:id))
          spreadsheet_column.position = index + 1
          spreadsheet_column.save
        else
          # otherwise update field if anything changed
          spreadsheet_column = @transcription_field.spreadsheet_columns.find(column[:id])
          spreadsheet_column.position = index + 1
          spreadsheet_column.update(column.except(:id))
        end
      end
    end
    if errors[:base].any?
      flash[:error] = errors[:base].uniq.join(' ')
    end
    if params[:done].nil?
      redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)
    else
      redirect_to transcription_field_edit_fields_path(collection_id: @collection.slug)
    end
  end

  # reordering functions
  def reorder_columns
    require_permission(:collection_owner, @collection)

    columns = require_transcription_field.spreadsheet_columns
    Array(params[:column]).each_with_index do |id, index|
      columns.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def delete_column
    require_permission(:collection_owner, @collection)

    transcription_field = require_transcription_field
    column = transcription_field.spreadsheet_columns.find(params[:spreadsheet_column_id])
    column.remove_from_list
    column.destroy
    redirect_to transcription_field_spreadsheet_column_path(transcription_field.id)
  end

  def enable_ruler
    require_permission(:collection_owner, @collection)

    require_transcription_field.update(row_highlight: true)
    redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)
  end

  def disable_ruler
    require_permission(:collection_owner, @collection)

    require_transcription_field.update(row_highlight: false)
    redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)
  end

  def choose_offset
    require_permission(:collection_owner, @collection)

    require_transcription_field
    @page = @collection.pages.sample(1).first
    # shared/_osd_div builds collection_monitor_view_path from @work, which was never set
    # here, so the page raised a 500.
    @work = @page&.work
  end

  def save_offset
    require_permission(:collection_owner, @collection)

    transcription_field = require_transcription_field
    # load_objects_from_params loaded @page from page_id with no check on which collection it
    # belongs to. Re-scope it, so a page from another collection is a 404.
    @page = @collection.pages.find(params[:page_id])

    raw_selector = params[:selector]
    parts = raw_selector.split(',')
    raw_y = parts[1]
    raw_h = parts[3]

    transcription_field.top_offset = raw_y.to_f / @page.base_height
    transcription_field.bottom_offset = 1.0 - ((raw_h.to_f + raw_y.to_f).to_f / @page.base_height)
    transcription_field.save!
    ajax_redirect_to transcription_field_spreadsheet_column_path(transcription_field.id)
  end

  private

  # Resolves the collection being acted on from the most specific param available.
  #
  # A transcription field id (transcription_field_id or field_id) wins: @collection becomes
  # the field's own collection, replacing whatever load_objects_from_params set from
  # collection_id or page_id. If collection_id was also sent and names a different
  # collection, the ids don't belong together, so it's a 404.
  #
  # Otherwise @collection is whatever ApplicationController loaded from collection_id (nil
  # if absent, which require_permission then denies).
  def load_permission_context
    field_id = params[:transcription_field_id].presence || params[:field_id].presence
    return if field_id.nil?

    @transcription_field = TranscriptionField.find(field_id)
    field_collection = @transcription_field.collection

    if params[:collection_id].present? && @collection != field_collection
      raise ActiveRecord::RecordNotFound, "TranscriptionField #{field_id} is not in collection #{params[:collection_id]}"
    end

    @collection = field_collection
  end

  # For actions that need a field. The field has already been authorized through its
  # collection by load_permission_context + require_permission.
  def require_transcription_field
    @transcription_field || raise(ActiveRecord::RecordNotFound, 'transcription field id is required')
  end

  # Every field in @collection, transcription *and* metadata. Collection#transcription_fields
  # is scoped to transcription fields only, but add_fields / reorder_fields serve both.
  def collection_fields
    TranscriptionField.where(collection_id: @collection.id)
  end

  def transcription_field_params(fields)
    fields.permit(:label, :input_type, :options, :line_number, :page_number, :percentage)
  end

  def spreadsheet_column_params
    params.permit(:collection_id, :transcription_field_id, :starting_rows, spreadsheet_columns: [:label, :input_type, :options, :id])
  end
end
