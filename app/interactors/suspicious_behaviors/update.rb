class SuspiciousBehaviors::Update < ApplicationInteractor
  attr_accessor :suspicious_behavior

  def initialize(suspicious_behavior:, status:, user:)
    @suspicious_behavior = suspicious_behavior
    @status = status
    @user = user

    super
  end

  def perform
    raise StandardError, 'User cannot update this record' if @suspicious_behavior.collection&.owner_user_id != @user.id

    @suspicious_behavior.update!(
      status: @status,
      resolved_by_user_id: @user.id,
      resolved_at: Time.current
    )
  end
end
