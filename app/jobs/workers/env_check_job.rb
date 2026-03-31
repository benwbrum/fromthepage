# :nocov:
class Workers::EnvCheckJob < RecurringBaseJob
  queue_as :solid_queue_recurring

  def perform
    Workers::EnvCheck.new.call
  end
end
# :nocov:
