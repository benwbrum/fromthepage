# :nocov:
namespace :fromthepage do
  namespace :workers do
    desc 'SolidQueue Workers health check'
    task health_check: :environment do
      Workers::HealthCheck.new.call
    end
  end
end
# :nocov:
