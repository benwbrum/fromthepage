class Deed::CalculateJob < ApplicationJob
  queue_as :default

  # TODO: Exclude user_id for lint checks on unused vars for app/jobs/**/*
  def perform(user_id:, deed_id:)
    deed = Deed.find(deed_id)

    Deed::Calculate.new(
      deed: deed
    ).call
  end
end
