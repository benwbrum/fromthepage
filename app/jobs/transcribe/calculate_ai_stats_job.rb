class Transcribe::CalculateAiStatsJob < ApplicationJob
  queue_as :default

  def perform(page_id:, user_id:)
    page = Page.find(page_id)

    Transcribe::CalculateAiStats.new(page: page).call
  end
end
