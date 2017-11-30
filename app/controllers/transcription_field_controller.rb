class TranscriptionFieldController < ApplicationController
  before_filter :authorized?, :only => [:new, :edit_fields, :add_field]

  #no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil}

  def delete
    @collection = Collection.friendly.find(params[:collection_id])
    field = TranscriptionField.find_by(id: params[:field_id])
    field.destroy
    redirect_to edit_fields_path(collection_id: @collection)
  end

  def edit_fields
    @current_fields = @collection.transcription_fields.order(:line_number).order(:position)
  end

  def add_fields
    @collection = Collection.friendly.find(params[:collection_id])
    new_fields = params[:transcription_fields]
    new_fields.each do |fields|
      #ignore blank fields
      unless fields['line_number'].blank? || fields['label'].blank?
        if fields['id'].blank?
          #if the field doesn't exist, create a new one
          transcription_field = TranscriptionField.new(fields)
          transcription_field.collection_id = params[:collection_id]
          transcription_field.save
        else
          #otherwise update field if anything changed
          transcription_field = TranscriptionField.find_by(id: fields['id'])
          #remove ID from params before update
          fields.delete("id")
          transcription_field.update_attributes(fields)
        end
      end
    end
    if params[:done].nil?
      redirect_to edit_fields_path(collection_id: @collection)
    else
      redirect_to edit_collection_path(@collection.owner, @collection)
    end
  end

  # reordering functions
  def reorder_field
    @collection = Collection.friendly.find(params[:collection_id])
    field = TranscriptionField.find_by(id: params[:field_id])
    if(params[:direction]=='up')
      field.move_higher
    else
      field.move_lower
    end
    redirect_to edit_fields_path(collection_id: @collection)
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
