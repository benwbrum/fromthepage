class NotesController < ApplicationController
  include ActionView::Helpers::TextHelper
  DEFAULT_NOTES_PER_PAGE = 50
  PAGES_PER_SCREEN = 20

  def index
    filtered_notes

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  def edit
    @note = Note.find(params[:id])

    respond_to(&:turbo_stream)
  end

  def create
    unless user_signed_in?
      flash[:error] = t('.must_be_logged')
      ajax_redirect_to root_path

      return
    end

    @result = Note::Create.new(
      note_params: note_params,
      collection: @collection,
      work: @work,
      page: @page,
      user: current_user
    ).call

    respond_to(&:turbo_stream)
  end

  def update
    note = Note.find(params[:id])

    if !user_signed_in? || note.user != current_user
      ajax_redirect_to root_path

      return
    end

    @result = Note::Update.new(note: note, note_params: note_params).call

    respond_to(&:turbo_stream)
  end

  def destroy
    @note = Note.find(params[:id])

    unless user_signed_in? && (@note.user == current_user || current_user.like_owner?(@note.work))
      ajax_redirect_to root_path

      return
    end

    @note.destroy

    respond_to(&:turbo_stream)
  end

  def discussions
    @pages = @collection.pages
                        .where.not(last_note_updated_at: nil)
                        .reorder(last_note_updated_at: :desc)
                        .paginate(page: params[:page], per_page: PAGES_PER_SCREEN)
  end

  private

  def filtered_notes
    @sorting = (params[:sort] || 'time').to_sym
    @ordering = (params[:order] || 'DESC').downcase.to_sym
    @ordering = [:asc, :desc].include?(@ordering) ? @ordering : :desc

    if @collection.present?
      notes_scope = @collection.notes.includes(:user, :work, :page, { collection: :owner })
    else
      notes_scope = Note.all.includes(:user, :work, :page, { collection: :owner })
    end

    if params[:search]
      query = "%#{params[:search].to_s.downcase}%"

      notes_users = User.where(id: notes_scope.select(:user_id))
                        .where('LOWER(users.display_name) LIKE :search', search: "%#{query}%")
      notes_filter_by_user = notes_scope.where(user_id: notes_users.select(:id))

      notes_filter_by_note = notes_scope.where('LOWER(notes.title) LIKE :search', search: "%#{query}%")

      notes_pages = Page.where(id: notes_scope.select(:page_id))
                        .where('LOWER(pages.title) LIKE :search', search: "%#{query}%")
      notes_filter_by_page = notes_scope.where(page_id: notes_pages.select(:id))

      notes_works = Work.where(id: notes_scope.select(:work_id))
                        .where('LOWER(works.title) LIKE :search', search: "%#{query}%")
      notes_filter_by_work = notes_scope.where(work_id: notes_works.select(:id))

      notes_scope = notes_filter_by_user.or(notes_filter_by_note)
                                        .or(notes_filter_by_page)
                                        .or(notes_filter_by_work)
    end

    case @sorting
    when :user
      notes_scope = notes_scope.reorder("users.display_name #{@ordering}")
    when :note
      notes_scope = notes_scope.reorder(title: @ordering)
    when :page
      notes_scope = notes_scope.reorder("pages.title #{@ordering}")
    when :work
      notes_scope = notes_scope.reorder("works.title #{@ordering}")
    else
      notes_scope = notes_scope.reorder(created_at: @ordering)
    end

    notes_scope = notes_scope.paginate(page: params[:page], per_page: DEFAULT_NOTES_PER_PAGE)
    @notes = notes_scope
  end

  def note_params
    params.require(:note).permit(:body)
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

end
