# frozen_string_literal: true

# Standalone integration checks; all synthetic database rows are rolled back.
# RAILS_ENV=test bundle exec rails runner script/la_county_ai_stats_test.rb
require 'minitest/autorun'
require 'tmpdir'
require_relative 'la_county_ai_stats'

raise 'Run these integration checks with RAILS_ENV=test' unless Rails.env.test?

class LaCountyAiStatsTest < Minitest::Test
  def setup
    @connection = ActiveRecord::Base.connection
    @connection.begin_transaction(joinable: false)
    @zone = ActiveSupport::TimeZone['America/Chicago']
    @collection_id = insert('collections', title: 'Synthetic report test', slug: "stats-test-#{SecureRandom.hex(8)}")
    @work_id = insert('works', collection_id: @collection_id)
  end

  def teardown
    @connection.rollback_transaction
  end

  def insert(table, attributes)
    names = attributes.keys.map { |key| @connection.quote_column_name(key) }.join(', ')
    values = attributes.values.map { |value| @connection.quote(value) }.join(', ')
    @connection.execute("INSERT INTO #{@connection.quote_table_name(table)} (#{names}) VALUES (#{values})")
    @connection.select_value('SELECT LAST_INSERT_ID()').to_i
  end

  def at(time)
    @zone.parse(time).utc
  end

  def page
    insert('pages', work_id: @work_id)
  end

  def deed(page_id, type, time, collection_id: @collection_id)
    insert('deeds', collection_id: collection_id, page_id: page_id, deed_type: type,
           created_at: at(time), updated_at: at(time))
  end

  def report(through = '2026-02-08')
    LaCountyAiStats::Report.new(collections: [Collection.find(@collection_id)],
                               through: Date.iso8601(through), zone: @zone).load_data
  end

  def test_periods_deduplication_ai_attribution_and_cumulative_baseline
    old, before, january, assisted, later_ai, version_ai = Array.new(6) { page }
    deed(old, 'page_trans', '2024-12-31 23:59:59')
    deed(before, 'page_trans', '2025-12-31 23:59:59')
    deed(before, 'page_trans', '2026-02-02 10:00:00') # repeated event is not a new page
    deed(january, 'page_trans', '2026-01-31 23:59:59')
    deed(assisted, 'ai_draft', '2026-02-01 00:00:00')
    deed(assisted, 'ai_draft', '2026-02-01 00:00:00')
    deed(assisted, 'page_trans', '2026-02-01 00:00:00')
    deed(later_ai, 'page_trans', '2026-02-03 11:00:00')
    deed(later_ai, 'ai_draft', '2026-02-04 11:00:00') # later edit stays separate
    deed(version_ai, 'page_trans', '2026-02-08 23:59:59')
    insert('page_versions', page_id: version_ai, ai_draft_used: true, created_on: at('2026-02-08 23:59:58'))
    deed(page, 'page_trans', '2026-02-09 00:00:00') # exclusive end
    deed(page, 'page_edit', '2026-02-02 11:00:00')
    deed(page, 'page_trans', '2026-02-02 11:00:00', collection_id: @collection_id + 999_999)
    before_stats, after_stats = report.summaries
    assert_equal 1, before_stats['Pages Transcribed']
    assert_equal 1, before_stats['Cumulative Pages before Start']
    assert_equal 3, after_stats['Pages Transcribed']
    assert_equal 2, after_stats['Pages Using AI at First Transcription']
    assert_equal 1, after_stats['Pages without Recorded AI Use at First Transcription']
    assert_equal 3, after_stats['AI Import Events']
    assert_equal 2, after_stats['Distinct Pages with AI Import in Period']
    assert_equal 3, after_stats['Cumulative Pages before Start']
    assert_equal 6, after_stats['Cumulative Pages at End']
    assert_in_delta 2.625, after_stats['Pages per Week'], 0.0001
    assert_in_delta 66.6667, after_stats['Pages Using AI Drafts (%)'], 0.0001
  end

  def test_availability_counts_distinct_pages_and_legacy_text_but_not_failed_or_future_drafts
    first = page
    [first, first].each do |id|
      insert('ai_transcriptions', page_id: id, model: 'test', status: 'finished', source_text: 'Draft',
             created_at: at('2026-02-01 00:00:00'), updated_at: at('2026-02-01 00:01:00'))
    end
    insert('ai_transcriptions', page_id: page, model: 'test (migrated)', status: 'new', source_text: 'Old draft',
           created_at: at('2026-02-02 00:00:00'), updated_at: at('2026-02-02 00:01:00'))
    %w[error processing].each do |status|
      insert('ai_transcriptions', page_id: page, model: 'test', status: status, source_text: 'Draft',
             created_at: at('2026-02-02 00:00:00'), updated_at: at('2026-02-02 00:01:00'))
    end
    insert('ai_transcriptions', page_id: page, model: 'test', status: 'finished', source_text: ' ',
           transcription_json: '{}', created_at: at('2026-02-02 00:00:00'), updated_at: at('2026-02-02 00:01:00'))
    insert('ai_transcriptions', page_id: page, model: 'test', status: 'finished', source_text: 'Draft',
           created_at: at('2026-02-09 00:00:00'), updated_at: at('2026-02-09 00:01:00'))
    assert_equal 2, report.summaries.last['Pages with AI Draft Available (Record-Date Proxy)']
  end

  def test_zero_weeks_partial_week_weighted_rates_and_daylight_saving
    deed(page, 'page_trans', '2026-03-08 03:30:00')
    result = report('2026-03-10')
    assert_equal 0, result.weekly.first['Pages Transcribed (Weekly)']
    assert_nil result.weekly.first['Pages Using AI Drafts (%)']
    assert_equal '2025-01-01', result.weekly.first['Week']
    assert_equal '2026-03-11', result.weekly.last['Week End (Exclusive)']
    assert_equal 38, result.summaries.last['Calendar Days']
    assert_in_delta 7.0 / 38, result.summaries.last['Pages per Week'], 0.0001
    assert_equal 7, result.metrics(Date.new(2026, 3, 4), Date.new(2026, 3, 11))['Calendar Days']
    partial = report('2026-02-08').weekly.last
    assert_equal 5, partial['Calendar Days']
    assert_equal true, partial['Partial Week']
    assert_nil result.comparison.first['Change (%)'] # zero baseline
  end

  def test_export_is_read_only_and_refuses_to_overwrite
    deed(page, 'page_trans', '2026-02-01 12:00:00')
    writes = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      writes << payload[:sql] if payload[:sql].match?(/\A\s*(INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|TRUNCATE)\b/i)
    end
    Dir.mktmpdir do |parent|
      directory = File.join(parent, 'report')
      ActiveSupport::Notifications.subscribed(subscriber, 'sql.active_record') do
        stdout, stderr = capture_io do
          LaCountyAiStats.run(['--collection-ids', @collection_id.to_s,
                               '--through', '2026-02-08', '--out', directory])
        end
        assert_includes stdout, 'Wrote weekly.csv, summary.csv, comparison.csv, and methodology.json'
        assert_empty stderr
      end
      assert_empty writes
      assert_equal 2, CSV.read(File.join(directory, 'summary.csv'), headers: true).size
      assert_equal 'America/Chicago', JSON.parse(File.read(File.join(directory, 'methodology.json')))['time_zone']
      assert_raises(Errno::EEXIST) { report.write(directory) }
    end
  end
end
