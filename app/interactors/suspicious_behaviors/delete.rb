class SuspiciousBehaviors::Delete < ApplicationInteractor
  attr_accessor :suspicious_behavior

  def initialize(suspicious_behavior:, user:)
    @suspicious_behavior = suspicious_behavior
    @user = user

    super
  end

  def perform
    raise StandardError, 'User cannot delete this record' unless user_has_permission?

    @suspicious_behavior.destroy!
  end

  private

  def user_has_permission?
    @user.like_owner?(@suspicious_behavior.collection) || @user.collaborator?(@suspicious_behavior.collection)
  end
end
