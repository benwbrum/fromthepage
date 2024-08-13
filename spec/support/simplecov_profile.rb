if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  require 'simplecov-lcov'

  if ENV['CI'] == 'true'
    SimpleCov::Formatter::LcovFormatter.config do |c|
      c.report_with_single_file = true
      c.single_report_path = 'coverage/lcov.info'
    end
    SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new(
      [
        SimpleCov::Formatter::HTMLFormatter,
        SimpleCov::Formatter::LcovFormatter
      ]
    )
  else
    SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  end

  SimpleCov.start 'rails' do
    add_group 'Interactors', '/app/interactors/'

    enable_coverage :branch

    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/vendor/'
    add_filter '/.bundle/'
  end
end
