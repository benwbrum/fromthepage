class TranscriptionFieldController < ApplicationController
  include ActiveModel::Validations
  before_filter :authorized?, :only => [:new, :edit_fields, :add_field]

  #no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil}

  def delete
    @collection = Collection.friendly.find(params[:collection_id])
    field = TranscriptionField.find_by(id: params[:field_id])
    field.remove_from_list
    field.destroy
    redirect_to collection_edit_fields_path(@collection.owner, @collection)
  end

  def edit_fields
    @current_fields = @collection.transcription_fields.order(:line_number).order(:position)
  end

  def add_fields
    @collection = Collection.friendly.find(params[:collection_id])
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
            errors.add(:base, "Select fields must have an options list.  Please add options to any select fields and resave.")
          end
        else
          fields[:options].gsub!(/;\s/, ';')
        end
        if fields[:id].blank?
          #if the field doesn't exist, create a new one
          transcription_field = TranscriptionField.new(fields)
          transcription_field.collection_id = params[:collection_id]
          transcription_field.save
        else
          #otherwise update field if anything changed
          transcription_field = TranscriptionField.find_by(id: fields[:id])
          #remove ID from params before update
          fields.delete(:id)
          transcription_field.update_attributes(fields)
        end
      end
    end
    if errors[:base].any?
      flash[:error] = errors[:base].uniq.join(" ")
    end
    if params[:done].nil?
      redirect_to collection_edit_fields_path(@collection.owner, @collection)
    else
      redirect_to edit_collection_path(@collection.owner, @collection)
    end
  end

  # reordering functions
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
    respond_to do |format|
      format.js
    end
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

end
