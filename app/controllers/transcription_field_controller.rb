class TranscriptionFieldController < ApplicationController
  include ActiveModel::Validations
  before_action :authorized?, :only => [:new, :edit_fields, :add_field]

  #no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil}

  def multiselect_form
    @transcription_field = TranscriptionField.find_by(id: params[:transcription_field_id])
    @collection = @transcription_field.collection
  end

  def save_multiselect
    @transcription_field = TranscriptionField.find_by(id: params[:transcription_field_id])
    @transcription_field.options = params[:options]
    @transcription_field.save!
    @collection = @transcription_field.collection
    ajax_redirect_to collection_edit_metadata_fields_path(@collection.owner, @collection)
  end

  def delete
    @collection = Collection.friendly.find(params[:collection_id])
    field = TranscriptionField.find_by(id: params[:field_id])
    field.remove_from_list
    field.destroy
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def edit_fields
    @current_fields = @collection.transcription_fields.order(:line_number).order(:position)
    @field_preview = {}
  end

  def edit_metadata_fields
    @current_fields = @collection.metadata_fields.order(:line_number).order(:position)
    @field_preview = {}
  end

  def add_fields
    @collection = Collection.friendly.find(params[:collection_id])

    if params[:description_instructions]
      @collection.update(:description_instructions => params[:description_instructions])
    end
    if params[:data_entry_type]
      @collection.update(:data_entry_type => params[:data_entry_type])
    end

    field_type = params[:field_type]
    new_fields = params[:transcription_fields]


    new_fields.each_with_index do |fields, index|
      if fields[:line_number] == "new"
        fields[:line_number] = new_fields[index-1][:line_number]
      end
      #ignore blank fields
      unless fields[:line_number].blank? || fields[:label].blank?
        if fields[:options].blank?
          fields[:options] = nil
          if fields[:input_type] == "select"
            fields[:input_type] = "text"
            errors.add(:base, t('.must_have_options_list'))
          end
        else
          fields[:options].gsub!(/;\s/, ';')
        end
        if fields[:id].blank?
          #if the field doesn't exist, create a new one
          transcription_field = TranscriptionField.new(fields.permit!)
          transcription_field.starting_rows = 1
          transcription_field.collection_id = params[:collection_id]
          transcription_field.field_type = field_type
          transcription_field.save
        else
          #otherwise update field if anything changed
          transcription_field = TranscriptionField.find_by(id: fields[:id])
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
      flash[:error] = errors[:base].uniq.join(" ")
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
    @collection = Collection.friendly.find(params[:collection_id])
    params[:field].each_with_index do |id, index|
      TranscriptionField.where(id: id).update_all(position: index + 1, line_number: params[:line])
    end
    head :ok
  end

  def reorder_field
    @collection = Collection.friendly.find(params[:collection_id])
    field = TranscriptionField.find_by(id: params[:field_id])
    if(params[:direction]=='up')
      if field.line_number != field.higher_item.line_number
        field.update_columns(line_number: field.higher_item.line_number)
      else
        field.move_higher
      end
    else
      if field.line_number != field.lower_item.line_number
        field.update_columns(line_number: field.lower_item.line_number)
      else
        field.move_lower
      end
    end
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def line_form
    @line_count = params[:line_count].strip.next
    @count = @line_count.split(" ").last.to_i
    @field_type = params[:field_type]
    respond_to do |format|
      format.js
    end
  end



  # Spreadsheet column actions
  def column_form
    @line_count = 1
    @count = 1
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    respond_to do |format|
      format.js
    end
  end

  def edit_columns
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    @collection = @transcription_field.collection
    @current_columns = @transcription_field.spreadsheet_columns.order(:position)
  end

  def add_columns
    @collection = Collection.friendly.find(spreadsheet_column_params[:collection_id])

    @transcription_field = TranscriptionField.find(spreadsheet_column_params[:transcription_field_id])
    if params[:starting_rows].blank?
      errors.add(:base, t('.starting_rows_must_not_be_blank'))
    else
      @transcription_field.update(:starting_rows => params[:starting_rows].to_i)
    end

    new_columns = spreadsheet_column_params[:spreadsheet_columns]

    new_columns.each_with_index do |column, index|
      #ignore blank fields
      unless column[:label].blank?
        if column[:options].blank?
          column[:options] = nil
          if column[:input_type] == "select"
            column[:input_type] = "text"
            errors.add(:base, t('.must_have_options_list'))
          end
        else
          column[:options].gsub!(/;\s/, ';')
        end

        if column[:id].blank?
          #if the field doesn't exist, create a new one
          spreadsheet_column = SpreadsheetColumn.new(column)
          spreadsheet_column.transcription_field = @transcription_field
          spreadsheet_column.position = index + 1
          spreadsheet_column.save
        else
          #otherwise update field if anything changed
          spreadsheet_column = SpreadsheetColumn.find_by(id: column[:id])
          #remove ID from params before update
          column.delete(:id)
          spreadsheet_column.position = index + 1
          spreadsheet_column.update(column)
        end
      end
    end
    if errors[:base].any?
      flash[:error] = errors[:base].uniq.join(" ")
    end
    if params[:done].nil?
      redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)
    else
      redirect_to transcription_field_edit_fields_path(:collection_id => @collection.slug)
    end
  end

  # reordering functions
  def reorder_columns
    @collection = Collection.friendly.find(params[:collection_id])
    transcription_field = TranscriptionField.find_by(id: params[:field_id])
    params[:column].each_with_index do |id, index|
      SpreadsheetColumn.where(id: id).update_all(position: index + 1)
    end
    head :ok
  end

  def delete_column
    @collection = Collection.friendly.find(params[:collection_id])
    transcription_field = TranscriptionField.find_by(id: params[:field_id])
    column = SpreadsheetColumn.find_by(id: params[:spreadsheet_column_id])
    column.remove_from_list
    column.destroy
    redirect_to transcription_field_spreadsheet_column_path(transcription_field.id)
  end

  def enable_ruler
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    @transcription_field.update(:row_highlight => true)
    redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)    
  end

  def disable_ruler
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    @transcription_field.update(:row_highlight => false)
    redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)    
  end

  def choose_offset
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    @collection = @transcription_field.collection
    @page = @collection.pages.sample(1).first
  end

  def save_offset
    @transcription_field = TranscriptionField.find(params[:transcription_field_id])
    raw_selector = params[:selector]
    parts = raw_selector.split(",")
    raw_y = parts[1]
    raw_h = parts[3]

    @transcription_field.top_offset = raw_y.to_f / @page.base_height
    @transcription_field.bottom_offset = 1.0 - ((raw_h.to_f + raw_y.to_f).to_f / @page.base_height)
    @transcription_field.save!
    ajax_redirect_to transcription_field_spreadsheet_column_path(@transcription_field.id)
  end

  private

  def spreadsheet_column_params
    params.permit(:collection_id, :transcription_field_id, :starting_rows, spreadsheet_columns: [:label, :input_type, :options, :id])
  end

  def authorized?
    unless user_signed_in?
      ajax_redirect_to dashboard_path
    end

    if @collection &&  !current_user.like_owner?(@collection)
      ajax_redirect_to dashboard_path
    end
  end

end
