class Transcribe::MarkAsBlank < ApplicationInteractor
  attr_accessor :page

  def initialize(page:, user:)
    @page = page
    @user = user

    super
  end

  def perform
    @page = Transcribe::Lib::MarkAsBlankHandler.new(
      page: @page,
      page_params: { mark_blank: '1' },
      user: @user
    ).perform
  end
end
