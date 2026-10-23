class Note::Create < ApplicationInteractor
  attr_accessor :note

  def initialize(note_params:, collection:, work:, page:, user:)
    @note_params = note_params
    @collection  = collection
    @work        = work
    @page        = page
    @user        = user

    super
  end

  def perform
    @note = Note.new(@note_params)

    @note.title = @note.body
    @note.title = @note.title.truncate(Note::MAX_TITLE_LENGTH)

    @note.collection_id = @collection.id
    @note.user_id = @user.id
    @note.work_id = @work&.id
    @note.page_id = @page&.id

    @note.save!
  end
end
