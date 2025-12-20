class SuspiciousBehaviors::Create < ApplicationInteractor
  attr_accessor :suspicious_behavior

  def initialize(collection:, page:, user:, suspicious_behavior_params:)
    @collection = collection
    @page = page
    @user = user
    @suspicious_behavior_params = suspicious_behavior_params

    super
  end

  def perform
    @suspicious_behavior = SuspiciousBehavior.new(
      user_id: @user.id,
      collection_id: @collection.id,
      page_id: @page.id
    )

    @suspicious_behavior.attributes = @suspicious_behavior_params

    @suspicious_behavior.save!
  end
end
