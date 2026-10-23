class Transcribe::FlagAiUseJob < ApplicationJob
  queue_as :default

  def perform(page_id:, user_id:)
    page = Page.find(page_id)
    user = User.find(user_id)

    Transcribe::FlagAiUse.new(
      page: page,
      user: user
    ).call
  end
end
