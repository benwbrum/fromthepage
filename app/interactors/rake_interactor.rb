# frozen_string_literal: true
require 'rake'

class RakeInteractor
  include Interactor

  def initialize(task_name: '', args: {}, log_file: nil)
    @task_name = task_name
    @args      = args
    @log_file  = log_file || "#{Rails.root}/log/rake.log"

    super
  end

  def call
    old_stdout = $stdout
    log_buffer = StringIO.new
    $stdout = log_buffer

    begin
      Rake.application.init
      Rake.application.load_rakefile
      Rake::Task[@task_name].reenable
      Rake::Task[@task_name].invoke(*@args.values)
    rescue => e
      puts "#{e.class}: #{e.message}"
      puts e.backtrace.join("\n")
    ensure
      $stdout = old_stdout

      File.new(@log_file, 'w').close unless File.exist?(@log_file)

      File.open(@log_file, 'a') do |f|
        f.puts log_buffer.string
      end

      Rake::Task.clear
    end
  end
end
