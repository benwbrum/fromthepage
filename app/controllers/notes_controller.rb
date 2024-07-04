class NotesController < ApplicationController

  include ActionView::Helpers::TextHelper
  PAGES_PER_SCREEN = 20

  def show
    @note = Note.find(params[:id])
  end

  def edit
    @note = Note.find(params[:id])
  end

  def create
    @note = Note.new(note_params)
    # truncate the body for the title
    @note.title = @note.body
    @note.title = truncate(@note.title, length: 250, escape: false)
    # add param-loaded associations
    @note.page = @page
    @note.work = @work
    @note.collection = @work.collection
    @note.user = current_user

    respond_to do |format|
      if !user_signed_in?
        format.html { redirect_back fallback_location: root_path, flash: { error: t('.must_be_logged') } }
      elsif @note.save
        record_deed
        format.json do
          render json: { html: render_to_string(partial: 'note.html', locals: { note: @note }, formats: [:html]) }, status: :created
        end
        format.html { redirect_back fallback_location: @note, notice: t('.note_has_been_created') }
      else
        format.json { render json: @note.errors.full_messages, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: @note, flash: { error: t('.error_creating_note') } }
      end
    end
  end

  def update
    @note = Note.find(params[:id])
    respond_to do |format|
      if @note.update(note_params)
        note_body = sanitize(@note.body, tags: ['strong', 'b', 'em', 'i', 'a'], attributes: ['href'])

        format.json { render json: { html: simple_format(note_body) }, status: :ok }
        format.html { redirect_back fallback_location: @note, notice: t('.note_has_been_updated') }
      else
        format.json { render json: @note.errors.full_messages, status: :unprocessable_entity }
        format.html { redirect_back fallback_location: @note, flash: { error: t('.error_updating_note') } }
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.deed.delete
    @note.delete
    respond_to do |format|
      format.json { head :no_content }
      format.html { redirect_back fallback_location: root_path, notice: t('.note_has_been_deleted') }
    end
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @work.collection
    deed.deed_type = DeedType::NOTE_ADDED
    deed.user = current_user

    deed.save!
    update_search_attempt_contributions
  end

  def discussions
    @pages = @collection.pages.where.not(last_note_updated_at: nil).reorder(last_note_updated_at: :desc).paginate page: params[:page],
      per_page: PAGES_PER_SCREEN
  end

  def list
    respond_to do |format|
      format.html
      format.json do
        render json: NoteDatatable.new(
          params,
          view_context:,
          collection_id: params[:collection_id]
        )
      end
    end
  end

  private

  def note_params
    params.require(:note).permit(:body)
  end

end
