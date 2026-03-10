class SuspiciousBehaviors::Update < ApplicationInteractor
  attr_accessor :suspicious_behavior

  def initialize(suspicious_behavior:, status:, user:)
    @suspicious_behavior = suspicious_behavior
    @status = status
    @user = user

    super
  end

  def perform
    raise StandardError, 'User cannot update this record' unless user_has_permission?

    @suspicious_behavior.update!(
      status: @status,
      resolved_by_user_id: @user.id,
      resolved_at: Time.current
    )
  end

  private

  def user_has_permission?
    @user.like_owner?(@suspicious_behavior.collection) || @user.collaborator?(@suspicious_behavior.collection)
  end
end
