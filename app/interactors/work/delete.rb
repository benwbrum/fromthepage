class Work::Delete < ApplicationInteractor
  attr_accessor :work

  def initialize(work:, user:)
    @work = work
    @user = user

    super
  end

  def perform
    validate_permission

    @work.destroy!
  end

  private

  def validate_permission
    return if @user.like_owner?(@work)

    raise ArgumentError, 'User has no permission to delete the work'
  end
end
