class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  before_perform :set_current_user

  private

  def set_current_user
    args = arguments.first

    unless args.is_a?(Hash) && args.key?(:user_id)
      raise ArgumentError, 'All jobs must receive a Hash with a `:user_id` key'
    end

    Current.user = User.find_by(id: args[:user_id])
  end
end
