if Settings.enable_delayed_job
  Delayed::Worker.destroy_failed_jobs = false
  Delayed::Worker.sleep_delay = 60
  Delayed::Worker.max_attempts = 3
  Delayed::Worker.max_run_time = 60.minutes
  Delayed::Worker.read_ahead = 10
  Delayed::Worker.default_queue_name = 'default'
  Delayed::Worker.delay_jobs = !Rails.env.test?
  Delayed::Worker.raise_signal_exceptions = :term
  Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'delayed_job.log'))

  DelayedJobWeb.use Rack::Auth::Basic do |username, password|
    user = User.find_by(login: username)
    user&.valid_password?(password) && user.admin?
  end
end
