#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'optparse'
require 'time'
require 'uri'

ApacheEntry = Struct.new(
  :line_number,
  :timestamp,
  :method,
  :path,
  :status,
  :duration,
  :raw,
  keyword_init: true
)

RailsEntry = Struct.new(
  :line_number,
  :timestamp,
  :method,
  :path,
  :raw,
  keyword_init: true
)

Match = Struct.new(:apache_entry, :rails_entry, :delta, keyword_init: true)

class LogMatcher
  APACHE_REQUEST_PATTERN = /
    \[(?<timestamp>[^\]]+)\]\s+
    "(?<method>[A-Z]+)\s+(?<path>\S+)(?:\s+HTTP\/[^"]*)?"\s+
    (?<status>\d{3}|-)
  /x

  RAILS_STARTED_PATTERN = /
    Started\s+
    (?<method>[A-Z]+)\s+
    "(?<path>[^"]+)"\s+
    for\s+
    .*?\s+
    at\s+
    (?<timestamp>.+)$
  /x

  attr_reader :apache_entries, :rails_entries, :matches, :unmatched_apache_entries

  def initialize(apache_log:, rails_log:, start_time:, end_time:, before_seconds:, after_seconds:)
    @apache_log = apache_log
    @rails_log = rails_log
    @start_time = start_time
    @end_time = end_time
    @before_seconds = before_seconds
    @after_seconds = after_seconds
    @apache_entries = []
    @rails_entries = []
    @matches = []
    @unmatched_apache_entries = []
  end

  def call
    @apache_entries = parse_apache_entries
    @rails_entries = parse_rails_entries
    match_entries
  end

  def rails_search_start_time
    @start_time - @before_seconds
  end

  def rails_search_end_time
    @end_time + @after_seconds
  end

  private

  def parse_apache_entries
    entries = []

    File.foreach(@apache_log).with_index(1) do |line, line_number|
      match = line.match(APACHE_REQUEST_PATTERN)
      next unless match

      timestamp = parse_time(match[:timestamp])
      next unless timestamp && timestamp >= @start_time && timestamp <= @end_time

      entries << ApacheEntry.new(
        line_number: line_number,
        timestamp: timestamp,
        method: match[:method],
        path: normalize_path(match[:path]),
        status: match[:status],
        duration: apache_duration(line),
        raw: line.chomp
      )
    end

    entries
  end

  def parse_rails_entries
    entries = []

    File.foreach(@rails_log).with_index(1) do |line, line_number|
      match = line.match(RAILS_STARTED_PATTERN)
      next unless match

      timestamp = parse_time(match[:timestamp])
      next unless timestamp

      next unless timestamp >= rails_search_start_time && timestamp <= rails_search_end_time

      entries << RailsEntry.new(
        line_number: line_number,
        timestamp: timestamp,
        method: match[:method],
        path: normalize_path(match[:path]),
        raw: line.chomp
      )
    end

    entries
  end

  def match_entries
    rails_entries_by_key = @rails_entries.group_by { |entry| [entry.method, entry.path] }
    used_rails_entries = {}

    @apache_entries.each do |apache_entry|
      candidate = rails_entries_by_key.fetch([apache_entry.method, apache_entry.path], [])
                                        .reject { |entry| used_rails_entries[entry.object_id] }
                                        .select { |entry| within_match_window?(apache_entry, entry) }
                                        .min_by { |entry| (apache_entry.timestamp - entry.timestamp).abs }

      if candidate
        used_rails_entries[candidate.object_id] = true
        @matches << Match.new(
          apache_entry: apache_entry,
          rails_entry: candidate,
          delta: candidate.timestamp - apache_entry.timestamp
        )
      else
        @unmatched_apache_entries << apache_entry
      end
    end
  end

  def within_match_window?(apache_entry, rails_entry)
    rails_entry.timestamp >= apache_entry.timestamp - @before_seconds &&
      rails_entry.timestamp <= apache_entry.timestamp + @after_seconds
  end

  def normalize_path(path)
    uri = URI.parse(path)
    normalized_path = uri.path.empty? ? '/' : uri.path
    uri.query ? "#{normalized_path}?#{uri.query}" : normalized_path
  rescue URI::InvalidURIError
    path
  end

  def parse_time(value)
    if value.match?(%r{\A\d{2}/[A-Za-z]{3}/\d{4}:})
      Time.strptime(value, '%d/%b/%Y:%H:%M:%S %z')
    else
      Time.parse(value)
    end
  rescue ArgumentError
    nil
  end

  def apache_duration(line)
    # Supports log formats that include key/value duration fields such as:
    # duration_us=12345, duration=12345, request_time=1.234, or rt=1.234.
    line[/\b(?:duration_us|duration)=(\d+(?:\.\d+)?)\b/, 1] ||
      line[/\b(?:request_time|rt)=(\d+(?:\.\d+)?)\b/, 1]
  end
end

options = {
  before_seconds: 120,
  after_seconds: 5,
  output: nil
}

parser = OptionParser.new do |opts|
  opts.banner = <<~BANNER
    Usage:
      ruby script/match_apache_rails_logs.rb --apache-log PATH --rails-log PATH --start TIME --end TIME [options]

    Example:
      ruby script/match_apache_rails_logs.rb \\
        --apache-log /var/log/apache2/access.log \\
        --rails-log /srv/fromthepage/current/log/production.log \\
        --start "2026-07-15 12:00:00 UTC" \\
        --end "2026-07-15 13:00:00 UTC" \\
        --output unmatched.csv
  BANNER

  opts.on('--apache-log PATH', 'Path to the Apache access log') { |value| options[:apache_log] = value }
  opts.on('--rails-log PATH', 'Path to the Rails production log') { |value| options[:rails_log] = value }
  opts.on('--start TIME', 'Start time, parseable by Ruby Time.parse') { |value| options[:start_time] = Time.parse(value) }
  opts.on('--end TIME', 'End time, parseable by Ruby Time.parse') { |value| options[:end_time] = Time.parse(value) }
  opts.on('--before SECONDS', Integer, 'Seconds before Apache timestamp to search for Rails start; default 120') do |value|
    options[:before_seconds] = value
  end
  opts.on('--after SECONDS', Integer, 'Seconds after Apache timestamp to search for Rails start; also extends Rails log search past --end; default 5') do |value|
    options[:after_seconds] = value
  end
  opts.on('--output PATH', 'Write unmatched Apache requests to CSV') { |value| options[:output] = value }
end

parser.parse!

missing_options = %i[apache_log rails_log start_time end_time].select { |key| options[key].nil? }
unless missing_options.empty?
  warn "Missing required options: #{missing_options.map { |key| "--#{key.to_s.tr('_', '-')}" }.join(', ')}"
  warn parser
  exit 1
end

matcher = LogMatcher.new(
  apache_log: options[:apache_log],
  rails_log: options[:rails_log],
  start_time: options[:start_time],
  end_time: options[:end_time],
  before_seconds: options[:before_seconds],
  after_seconds: options[:after_seconds]
)
matcher.call

puts "Apache requests in window: #{matcher.apache_entries.size}"
puts "Rails request starts in searchable window: #{matcher.rails_entries.size}"
puts "Rails searchable window: #{matcher.rails_search_start_time.iso8601} through #{matcher.rails_search_end_time.iso8601}"
puts "Matched Apache requests: #{matcher.matches.size}"
puts "Unmatched Apache requests: #{matcher.unmatched_apache_entries.size}"

if matcher.apache_entries.any?
  match_rate = (matcher.matches.size.to_f / matcher.apache_entries.size * 100).round(2)
  puts "Match rate: #{match_rate}%"
end

unless matcher.unmatched_apache_entries.empty?
  puts "\nUnmatched Apache requests by status:"
  matcher.unmatched_apache_entries.group_by(&:status).sort.each do |status, entries|
    puts "  #{status}: #{entries.size}"
  end

  puts "\nTop unmatched Apache paths:"
  matcher.unmatched_apache_entries.group_by(&:path)
         .sort_by { |_path, entries| -entries.size }
         .first(20)
         .each do |path, entries|
    puts "  #{entries.size.to_s.rjust(5)}  #{path}"
  end
end

if options[:output]
  CSV.open(options[:output], 'w') do |csv|
    csv << %w[apache_line apache_time method path status duration raw]
    matcher.unmatched_apache_entries.each do |entry|
      csv << [
        entry.line_number,
        entry.timestamp.iso8601,
        entry.method,
        entry.path,
        entry.status,
        entry.duration,
        entry.raw
      ]
    end
  end

  puts "\nWrote unmatched Apache request CSV to #{options[:output]}"
end
