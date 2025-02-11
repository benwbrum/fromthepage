class Note::Update < ApplicationInteractor
  attr_accessor :note

  def initialize(note:, note_params:)
    @note = note
    @note_params = note_params

    super
  end

  def perform
    @note.update!(@note_params)
  end
end
