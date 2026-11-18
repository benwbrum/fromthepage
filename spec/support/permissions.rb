# Prints the endpoints that need a permission decision at the end of the run:
# actions that used :pending, and actions in an `enforce_permission_checks` controller that
# never called `require_permission`. Warn-only: it never fails the suite.
RSpec.configure do |config|
  config.after(:suite) do
    warnings = Permissions.warnings
    next if warnings.empty?

    puts "\n[permissions] #{warnings.size} endpoint(s) need attention:"
    warnings.sort.each { |warning| puts "  #{warning.delete_prefix('[permissions] ')}" }
  end
end
