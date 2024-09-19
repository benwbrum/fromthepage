# frozen_string_literal: true

if Rails.env.development?
  require 'rack-mini-profiler'

  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.show_total_sql_count = true

  Rack::MiniProfilerRails.initialize!(Rails.application)
end
