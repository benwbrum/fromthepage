class Page::CalculateApprovalDeltaJob < ApplicationJob
  queue_as :default

  def perform(page_id:, user_id:)
    page = Page.find(page_id)

    Page::Lib::CalculateApprovalDelta.new(page: page).perform
  end
end
