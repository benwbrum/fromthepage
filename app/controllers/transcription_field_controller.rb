class TranscriptionFieldController < ApplicationController
  enforce_permission_checks

  # @collection is loaded from params[:collection_id] by ApplicationController, so every
  # action that acts on a field receives collection_id and looks the field up *through*
  # @collection. A field id from another collection is a 404.

  def multiselect_form
    require_permission(:collection_owner, @collection)

    # multiselect is a metadata-only input type
    @transcription_field = @collection.metadata_fields.find(params[:transcription_field_id])
  end

  def save_multiselect
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.metadata_fields.find(params[:transcription_field_id])
    transcription_field.options = params[:options]
    transcription_field.save!
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  end

  def delete
    require_permission(:collection_owner, @collection)

    # Serves both the transcription and the metadata field editors
    field = TranscriptionField.where(collection_id: @collection.id).find(params[:field_id])
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
    error_messages = []


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
            error_messages << t('.must_have_options_list')
          end
        else
          fields[:options].gsub!(/;\s/, ';')
        end
        if fields[:id].blank?
          # if the field doesn't exist, create a new one
          transcription_field = TranscriptionField.where(collection_id: @collection.id).new(transcription_field_params(fields))
          transcription_field.starting_rows = 1
          transcription_field.field_type = field_type
          transcription_field.save
        else
          # otherwise update field if anything changed
          transcription_field = TranscriptionField.where(collection_id: @collection.id).find(fields[:id])
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
    if error_messages.any?
      flash[:error] = error_messages.uniq.join(' ')
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

    # Serves both the transcription and the metadata field editors
    fields = TranscriptionField.where(collection_id: @collection.id)
    Array(params[:field]).each_with_index do |id, index|
      fields.where(id: id).update_all(position: index + 1, line_number: params[:line])
    end
    head :ok
  end

  def line_form
    # Renders an empty form row. It reads no record, but only the field editor of the
    # collection's owner calls it, so require that rather than just a signed-in user.
    require_permission(:collection_owner, @collection)

    @line_count = params[:line_count].to_s.strip.next
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
    @transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    respond_to do |format|
      format.js
    end
  end

  def edit_columns
    require_permission(:collection_owner, @collection)

    @transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    @current_columns = @transcription_field.spreadsheet_columns.order(:position)
  end

  def add_columns
    require_permission(:collection_owner, @collection)

    @transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    error_messages = []
    if params[:starting_rows].blank?
      error_messages << t('.starting_rows_must_not_be_blank')
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
            error_messages << t('.must_have_options_list')
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
    if error_messages.any?
      flash[:error] = error_messages.uniq.join(' ')
    end
    if params[:done].nil?
      redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id, collection_id: @collection)
    else
      redirect_to transcription_field_edit_fields_path(collection_id: @collection.slug)
    end
  end

  # reordering functions
  def reorder_columns
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.transcription_fields.find(params[:field_id])
    columns = transcription_field.spreadsheet_columns
    Array(params[:column]).each_with_index do |id, index|
      columns.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def delete_column
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.transcription_fields.find(params[:field_id])
    column = transcription_field.spreadsheet_columns.find(params[:spreadsheet_column_id])
    column.remove_from_list
    column.destroy
    redirect_to transcription_field_spreadsheet_column_path(transcription_field.id, collection_id: @collection)
  end

  def enable_ruler
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    transcription_field.update(row_highlight: true)
    redirect_to transcription_field_spreadsheet_column_path(transcription_field.id, collection_id: @collection)
  end

  def disable_ruler
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    transcription_field.update(row_highlight: false)
    redirect_to transcription_field_spreadsheet_column_path(transcription_field.id, collection_id: @collection)
  end

  def choose_offset
    require_permission(:collection_owner, @collection)

    @transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
    @page = @collection.pages.sample(1).first
    # shared/_osd_div builds collection_monitor_view_path from @work, which was never set
    # here, so the page raised a 500.
    @work = @page&.work
  end

  def save_offset
    require_permission(:collection_owner, @collection)

    transcription_field = @collection.transcription_fields.find(params[:transcription_field_id])
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
    ajax_redirect_to transcription_field_spreadsheet_column_path(transcription_field.id, collection_id: @collection)
  end

  private

  def transcription_field_params(fields)
    fields.permit(:label, :input_type, :options, :line_number, :page_number, :percentage)
  end

  def spreadsheet_column_params
    params.permit(:collection_id, :transcription_field_id, :starting_rows, spreadsheet_columns: [:label, :input_type, :options, :id])
  end
end
