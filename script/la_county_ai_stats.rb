# frozen_string_literal: true

# Run from the FromThePage root with:
# bundle exec rails runner script/la_county_ai_stats.rb --help
require 'csv'
require 'date'
require 'fileutils'
require 'json'
require 'optparse'

module LaCountyAiStats
  START_DATE = Date.new(2025, 1, 1)
  POST_DATE = Date.new(2026, 2, 1)
  WEEK_ANCHOR = START_DATE # Wednesday, matching the spreadsheet sent in May.

  class Report
    attr_reader :collections, :through, :zone, :first_transcriptions, :first_ai_use,
                :first_draft_records, :ai_imports

    def initialize(collections:, through:, zone:)
      raise ArgumentError, 'Through date must be on or after 2026-02-01' if through < POST_DATE

      @collections = collections
      @through = through
      @zone = zone
    end

    def midnight(date)
      zone.local(date.year, date.month, date.day)
    end

    def load_data
      ids = collections.map(&:id)
      cutoff = midnight(through + 1)
      # Do not truncate the history at 2025: it supplies the cumulative baseline
      # and prevents a later repeat transcription from becoming a new page.
      deeds = Deed.where(collection_id: ids).where.not(page_id: nil)
                  .where('created_at < ?', cutoff)
      pages = Page.joins(:work).where(works: { collection_id: ids }).select(:id)

      ActiveRecord::Base.transaction do
        @first_transcriptions = deeds.where(deed_type: DeedType::PAGE_TRANSCRIPTION)
                                     .group(:page_id).minimum(:created_at)
        @ai_imports = deeds.where(deed_type: DeedType::AI_DRAFT)
                           .pluck(:page_id, :created_at)
        @first_ai_use = ai_imports.each_with_object({}) do |(page_id, time), result|
          result[page_id] = [result[page_id], time].compact.min
        end
        PageVersion.where(page_id: pages, ai_draft_used: true)
                   .where('created_on < ?', cutoff)
                   .group(:page_id).minimum(:created_on).each do |page_id, time|
          @first_ai_use[page_id] = [@first_ai_use[page_id], time].compact.min
        end

        # Historical migration created records with text but status='new'.
        # Creation is only a proxy for availability; updated_at also changes
        # during accuracy recalculation and cannot serve as a completion date.
        @first_draft_records = AiTranscription.where(page_id: pages, status: %w[new finished])
          .where('created_at < ?', cutoff)
          .where("NULLIF(TRIM(source_text), '') IS NOT NULL OR " \
                 "(transcription_json IS NOT NULL AND TRIM(transcription_json) NOT IN ('', '{}', '[]', 'null'))")
          .group(:page_id).minimum(:created_at)
      end
      self
    end

    def ai_at_first_transcription?(page_id, time)
      first_ai_use[page_id] && first_ai_use[page_id] <= time
    end

    def metrics(start_date, end_date)
      from = midnight(start_date)
      to = midnight(end_date)
      transcribed = first_transcriptions.select { |_id, time| time >= from && time < to }
      ai_count = transcribed.count { |id, time| ai_at_first_transcription?(id, time) }
      imports = ai_imports.select { |_id, time| time >= from && time < to }
      days = (end_date - start_date).to_i
      total = transcribed.size
      {
        'Start Date' => start_date.iso8601,
        'End Date (Exclusive)' => end_date.iso8601,
        'Calendar Days' => days,
        'Pages Transcribed' => total,
        'Pages Using AI at First Transcription' => ai_count,
        'Pages without Recorded AI Use at First Transcription' => total - ai_count,
        'Pages Using AI Drafts (%)' => total.zero? ? nil : (100.0 * ai_count / total).round(4),
        'Pages per Week' => (7.0 * total / days).round(4),
        'AI Pages per Week' => (7.0 * ai_count / days).round(4),
        'Pages without Recorded AI Use per Week' => (7.0 * (total - ai_count) / days).round(4),
        'Cumulative Pages before Start' => first_transcriptions.count { |_id, time| time < from },
        'Cumulative Pages at End' => first_transcriptions.count { |_id, time| time < to },
        'Pages with AI Draft Available (Record-Date Proxy)' => first_draft_records.count { |_id, time| time < to },
        'AI Import Events' => imports.size,
        'Distinct Pages with AI Import in Period' => imports.map(&:first).uniq.size
      }
    end

    def summaries
      [
        { 'Period' => '2025' }.merge(metrics(START_DATE, Date.new(2026, 1, 1))),
        { 'Period' => 'February 2026 onward' }.merge(metrics(POST_DATE, through + 1))
      ]
    end

    def weekly
      rows = []
      start_date = START_DATE
      while start_date <= through
        end_date = [start_date + 7, through + 1].min
        m = metrics(start_date, end_date)
        # The first six columns follow the May spreadsheet's order. Additional
        # columns expose boundaries and distinguish imports during later edits.
        rows << {
          'Week' => start_date.iso8601,
          'Pages Transcribed (Weekly)' => m['Pages Transcribed'],
          'AI Drafts Used (Weekly)' => m['Pages Using AI at First Transcription'],
          'Cumulative Pages Transcribed' => m['Cumulative Pages at End'],
          'Pages with AI Draft Available (Record-Date Proxy)' => m['Pages with AI Draft Available (Record-Date Proxy)'],
          'Pages Using AI Drafts (%)' => m['Pages Using AI Drafts (%)'],
          'Week End (Exclusive)' => end_date.iso8601,
          'Calendar Days' => m['Calendar Days'],
          'Partial Week' => m['Calendar Days'] < 7,
          'Pages without Recorded AI Use' => m['Pages without Recorded AI Use at First Transcription'],
          'AI Import Events (Weekly)' => m['AI Import Events'],
          'Distinct Pages with AI Import (Weekly)' => m['Distinct Pages with AI Import in Period']
        }
        start_date = end_date
      end
      rows
    end

    def comparison
      before, after = summaries
      [
        'Pages per Week', 'AI Pages per Week', 'Pages without Recorded AI Use per Week'
      ].map do |metric|
        baseline = before.fetch(metric)
        current = after.fetch(metric)
        {
          'Metric' => metric,
          '2025' => baseline,
          'February 2026 onward' => current,
          'Absolute Change' => (current - baseline).round(4),
          'Change (%)' => baseline.zero? ? nil : (100.0 * (current / baseline - 1)).round(4)
        }
      end
    end

    def metadata
      {
        generated_at: Time.current.iso8601,
        through_inclusive: through.iso8601,
        time_zone: zone.tzinfo.name,
        weekly_anchor: WEEK_ANCHOR.iso8601,
        collections: collections.map { |c| { id: c.id, title: c.title, slug: c.slug } },
        definitions: {
          pages_transcribed: 'Distinct page IDs, dated by their earliest page_trans deed in the selected collections. This is first transcription activity, not QC approval or measured time spent.',
          ai_drafts_used: 'Among those first transcriptions, pages with an ai_draft deed or ai_draft_used page version at or before the first transcription timestamp. Later imports are reported separately.',
          without_recorded_ai: 'No recorded draft import at first transcription. Volunteers may still have viewed the AI tab or used outside tools.',
          draft_availability: 'Distinct current pages with a nonempty draft in a current new/finished record created before the bucket end. A record-date proxy, not a reconstructed historical snapshot.',
          percentages: 'Numeric percentage points (0 to 100), blank when denominator is zero. Period percentages use total counts, not the mean of weekly percentages.',
          weekly_rate: 'Total pages / (calendar days / 7), including zero-activity days. The final weekly row is clipped at the through date.',
          cumulative: 'All surviving first-transcription deed history before the bucket end, including activity before 2025 and during January 2026.'
        },
        limitations: [
          'The original May extraction code was not available. Column order and Wednesday buckets follow the spreadsheet, but exact historical parity has not been verified.',
          'January 2026 is retained in the weekly timeline and excluded from both requested comparison periods. Weeks crossing a period boundary must not be summed to obtain period totals; use summary.csv.',
          'AI record migration, regeneration, deletion, mutable status, and missing legacy files can distort the draft-availability proxy. No exact availability or tab-view history is inferred.',
          'Deleted history and collection moves can affect historical counts. AI records and page versions are scoped to the current pages in the selected collections.',
          'If the through date is today, today is incomplete and its full calendar day is included in the rate denominator. Use a completed date for stable comparisons.',
          'These are descriptive throughput comparisons. They do not establish that AI caused the change or measure transcription/QC minutes or accuracy.'
        ]
      }
    end

    def write(directory)
      # Refuse to overwrite an earlier report.
      FileUtils.mkdir_p(File.dirname(directory))
      Dir.mkdir(directory)
      { 'weekly.csv' => weekly, 'summary.csv' => summaries, 'comparison.csv' => comparison }.each do |filename, rows|
        CSV.open(File.join(directory, filename), 'w') do |csv|
          csv << rows.first.keys
          rows.each { |row| csv << row.values }
        end
      end
      File.write(File.join(directory, 'methodology.json'), JSON.pretty_generate(metadata) + "\n")
    end
  end

  def self.run(argv)
    options = { owner: 'lacountylibrary', timezone: 'America/Chicago' }
    parser = OptionParser.new do |opts|
      opts.banner = 'Usage: bundle exec rails runner script/la_county_ai_stats.rb [options]'
      opts.on('--owner SLUG', 'Owner slug (default: lacountylibrary)') { |v| options[:owner] = v }
      opts.on('--collection-ids IDS', 'Explicit collection IDs, comma separated; overrides --owner') do |v|
        raise OptionParser::InvalidArgument, 'Use positive integer IDs separated by commas' unless v.match?(/\A[1-9]\d*(,[1-9]\d*)*\z/)
        options[:ids] = v.split(',').map(&:to_i).uniq
      end
      opts.on('--through YYYY-MM-DD', 'Inclusive cutoff (default: today in report time zone)') do |v|
        raise OptionParser::InvalidArgument, 'Use YYYY-MM-DD' unless v.match?(/\A\d{4}-\d{2}-\d{2}\z/)
        options[:through] = Date.iso8601(v)
      end
      opts.on('--timezone ZONE', 'Default: America/Chicago, matching the May spreadsheet') { |v| options[:timezone] = v }
      opts.on('--out DIRECTORY', 'New output directory; existing directories are refused') { |v| options[:out] = v }
      opts.on('--list-collections', 'Print resolved collection IDs/titles and exit') { options[:list] = true }
      opts.on('-h', '--help') { puts opts; return }
    end
    parser.parse!(argv)
    raise OptionParser::InvalidArgument, "Unexpected arguments: #{argv.join(' ')}" unless argv.empty?

    zone = ActiveSupport::TimeZone[options[:timezone]]
    raise ArgumentError, "Unknown time zone: #{options[:timezone]}" unless zone

    today = Time.current.in_time_zone(zone).to_date
    through = options[:through] || today
    raise ArgumentError, 'Through date cannot be in the future' if through > today

    collections = if options[:ids]
      found = Collection.where(id: options[:ids]).order(:id).to_a
      missing = options[:ids] - found.map(&:id)
      raise ArgumentError, "Unknown collection IDs: #{missing.join(', ')}" if missing.any?
      found
    else
      owner = User.find_by(slug: options[:owner])
      raise ArgumentError, "Owner not found: #{options[:owner]}; use --owner or --collection-ids" unless owner
      Collection.where(owner_user_id: owner.id).order(:id).to_a
    end
    raise ArgumentError, 'No collections found for the requested scope' if collections.empty?

    collections.each { |c| puts "Collection #{c.id}: #{c.title} (#{c.slug})" }
    return if options[:list]

    directory = File.expand_path(options[:out] || Rails.root.join('tmp', "la_county_stats_#{Time.current.utc.strftime('%Y%m%dT%H%M%SZ')}"))
    raise ArgumentError, "Output directory already exists: #{directory}" if File.exist?(directory)

    report = Report.new(collections: collections, through: through, zone: zone).load_data
    warn 'No first-transcription deeds found in this scope; check the database and collection IDs.' if report.first_transcriptions.empty?
    report.write(directory)
    puts "Wrote weekly.csv, summary.csv, comparison.csv, and methodology.json to #{directory}"
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    LaCountyAiStats.run(ARGV)
  rescue OptionParser::ParseError, ArgumentError, Date::Error, Errno::EEXIST => e
    warn "Error: #{e.message}"
    exit 1
  end
end
