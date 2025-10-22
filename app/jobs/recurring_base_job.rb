class RecurringBaseJob < ActiveJob::Base
  retry_on StandardError, wait: 5.seconds, attempts: Settings.active_job.attempts
end
