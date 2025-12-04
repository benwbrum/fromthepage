class SuspiciousBehaviors::Delete < ApplicationInteractor
  attr_accessor :suspicious_behavior

  def initialize(suspicious_behavior:, user:)
    @suspicious_behavior = suspicious_behavior
    @user = user

    super
  end

  def perform
    raise StandardError, 'User cannot delete this record' if @suspicious_behavior.collection&.owner_user_id != @user.id

    @suspicious_behavior.destroy!
  end
end
