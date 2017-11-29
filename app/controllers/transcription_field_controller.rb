class TranscriptionFieldController < ApplicationController
  before_filter :authorized?, :only => [:new, :edit_fields, :add_field]

  #no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil}

  def edit_fields
    @current_fields = @collection.transcription_fields
  end

  def add_fields
    @collection = Collection.friendly.find(params[:collection_id])
    array = @collection.trascription_fields
    new_fields = params[:transcription_fields]
      new_fields.each do |fields|
        binding.pry
      transcription_field = TranscriptionField.new(fields)
      transcription_field.collection_id = params[:collection_id]
      transcription_field.save
    end
    @field_array = @collection.transcription_fields

    binding.pry
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
