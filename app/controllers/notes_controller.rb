class NotesController < ApplicationController

  def create
    @note = Note.new(params[:note])
    # truncate the body for the title
    @note.title = @note.body
    # add param-loaded associations
    @note.page = @page
    @note.work = @work
    if @collection.is_a?(Collection)
      @note.collection = @collection
    else
      @note.collection = @collection.collection
    end
    @note.user = current_user

    respond_to do |format|
      if not user_signed_in?
        format.html { redirect_to :back, flash: { error: "You must be logged in to create notes" } }
      elsif @note.save
        record_deed
        format.json { render json: { html: render_to_string(partial: 'note.html', locals: { note: @note }) }, status: :created }
        format.html { redirect_to :back, notice: "Note has been created" }
      else
        format.json { render json: @note.errors.full_messages, status: :unprocessable_entity }
        format.html { redirect_to :back, flash: { error: "Error creating note" } }
      end
    end
  end

  def update
    @note = Note.find(params[:id])
    respond_to do |format|
      if @note.update_attributes(params[:note])
        format.json { head :no_content }
        format.html { redirect_to :back, notice: "Note has been updated" }
      else
        format.json { render json: @note.errors.full_messages, status: :unprocessable_entity }
        format.html { redirect_to :back, flash: { error: "Error updating note" } }
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.deed.delete
    @note.delete
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_to :back, notice: "Note has been deleted" }
    end
  end

  def edit
    @note = Note.find(params[:id])
  end

  def show
    @note = Note.find(params[:id])
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    if @collection.is_a?(Collection)
      deed.collection = @collection
    else
      deed.collection = @collection.collection
    end

    deed.deed_type = Deed::NOTE_ADDED
    deed.user = current_user
    deed.save!
  end

end