# frozen_string_literal: true

require 'set'

# Produces the reproducible, production-database analysis used by the
# "Artificial Intelligence and Volunteer Behavior" conference proposal.
class AiVolunteerBehaviorReport
  Period = Data.define(:label, :starts_at, :ends_at)

  PERIODS = {
    'A' => Period.new(label: 'A', starts_at: Time.utc(2024, 2, 1), ends_at: Time.utc(2024, 8, 1)),
    'B' => Period.new(label: 'B', starts_at: Time.utc(2025, 2, 1), ends_at: Time.utc(2025, 8, 1)),
    'C' => Period.new(label: 'C', starts_at: Time.utc(2026, 2, 1), ends_at: Time.utc(2026, 8, 1))
  }.freeze
  SCOPES = { 'Raw (1+)' => 1, 'Serious (10+)' => 10, 'Super-participant (1000+)' => 1000 }.freeze
  AI_COLLECTION_MINIMUM = 100
  HEAVY_AI_MINIMUM = 10

  def initialize(output:, ai_collection_minimum: AI_COLLECTION_MINIMUM, heavy_ai_minimum: HEAVY_AI_MINIMUM)
    @output = output
    @ai_collection_minimum = ai_collection_minimum
    @heavy_ai_minimum = heavy_ai_minimum
  end

  def call
    $stdout.sync = true
    debug "Starting report; output=#{@output.inspect}, AI collection minimum=#{@ai_collection_minimum}, " \
          "heavy AI minimum=#{@heavy_ai_minimum}"

    @eligible_collection_ids = step('Finding AI-enabled collections') { eligible_collection_ids }
    debug "Eligible collections: #{@eligible_collection_ids.size} (IDs: #{list(@eligible_collection_ids)})"

    @contributions = {}
    @eligible_contributions = {}
    @active_eligible_collection_ids = {}
    @versions = {}

    PERIODS.each do |label, period|
      debug "Beginning period #{label}: #{period.starts_at.iso8601}...#{period.ends_at.iso8601}"

      @contributions[label] = step("Period #{label}: counting participants across all collections") do
        contribution_counts(period)
      end
      debug_contributions(label, 'all collections', @contributions[label])

      @eligible_contributions[label] = step("Period #{label}: counting participants in AI-enabled collections") do
        contribution_counts(period, collection_ids: @eligible_collection_ids)
      end
      debug_contributions(label, 'AI-enabled collections', @eligible_contributions[label])

      @active_eligible_collection_ids[label] = step("Period #{label}: finding active AI-enabled collections") do
        non_owner_deeds(period, collection_ids: @eligible_collection_ids).distinct.pluck(:collection_id).to_set
      end
      debug "Period #{label}: #{@active_eligible_collection_ids[label].size} AI-enabled collections had non-owner activity"

      @versions[label] = step("Period #{label}: loading saved page versions for AI-enabled collections") do
        version_rows(period, collection_ids: @eligible_collection_ids)
      end
      version_users = @versions[label].map(&:first).uniq.size
      version_pages = @versions[label].map { |row| row[1] }.uniq.size
      ai_versions = @versions[label].count { |row| row[4] }
      debug "Period #{label}: #{@versions[label].size} saved versions, #{version_users} users, " \
            "#{version_pages} pages, #{ai_versions} AI-assisted saves"
    end

    markdown = step('Rendering Markdown report') { render }
    step("Creating output directory #{File.dirname(@output)}") { FileUtils.mkdir_p(File.dirname(@output)) }
    step("Writing #{markdown.bytesize} bytes to #{@output}") { File.write(@output, markdown) }
    debug "Report complete: #{@output}"
    @output
  end

  private

  def eligible_collection_ids
    AiTranscription.joins(page: :work)
      .where(created_at: PERIODS.fetch('C').starts_at...PERIODS.fetch('C').ends_at)
      .group('works.collection_id')
      .having('COUNT(ai_transcriptions.id) >= ?', @ai_collection_minimum)
      .pluck('works.collection_id')
  end

  # AI_DRAFT is an audit marker emitted in addition to the saved-page deed, so
  # excluding it prevents one AI-assisted save from counting twice.
  def contribution_counts(period, collection_ids: nil)
    scope = non_owner_deeds(period, collection_ids: collection_ids)
    scope.group(:user_id).count
  end

  def non_owner_deeds(period, collection_ids: nil)
    scope = Deed.where(created_at: period.starts_at...period.ends_at)
      .where(deed_type: DeedType.collection_edits - [DeedType::AI_DRAFT])
      .where.not(user_id: nil).where.not(collection_id: nil)
      .where.not(<<~SQL.squish)
        EXISTS (SELECT 1 FROM collections WHERE collections.id = deeds.collection_id
                AND collections.owner_user_id = deeds.user_id)
        OR EXISTS (SELECT 1 FROM collection_owners WHERE collection_owners.collection_id = deeds.collection_id
                   AND collection_owners.user_id = deeds.user_id)
      SQL
    collection_ids.nil? ? scope : scope.where(collection_id: collection_ids)
  end

  def version_rows(period, collection_ids:)
    PageVersion.joins(page: { work: :collection })
      .where(created_on: period.starts_at...period.ends_at, works: { collection_id: collection_ids })
      .where.not(user_id: nil)
      .where.not(<<~SQL.squish)
        (collections.owner_user_id IS NOT NULL AND page_versions.user_id = collections.owner_user_id)
        OR EXISTS (SELECT 1 FROM collection_owners WHERE collection_owners.collection_id = collections.id
                   AND collection_owners.user_id = page_versions.user_id)
      SQL
      .pluck(:user_id, :page_id, 'works.collection_id', :created_on, :ai_draft_used)
  end

  def render
    sections = []
    {
      'methodology' => :header,
      'retention' => :retention,
      'adoption and switching' => :adoption,
      'productivity' => :productivity,
      'eligible collections' => :collections,
      'survey candidates' => :survey_candidates
    }.each do |label, method|
      sections << step("Rendering #{label} section") { send(method) }
    end
    sections.join("\n\n") + "\n"
  end

  def header
    <<~MD.chomp
      # Artificial Intelligence and Volunteer Behavior

      Generated at #{Time.current.utc.iso8601} from the production database.

      ## Method

      * Periods are half-open UTC ranges: A is 2024-02-01 through 2024-07-31, B is 2025-02-01 through 2025-07-31, and C is 2026-02-01 through 2026-07-31.
      * A contribution is a collection-edit deed, excluding the `ai_draft` audit deed so an AI-assisted save is not counted twice. Primary and additional collection owners are excluded per collection.
      * AI-enabled means at least #{@ai_collection_minimum} `ai_transcriptions` created during C (all statuses/models). The same fixed collection set is used when comparing A, B, and C.
      * AI use is a saved `page_versions.ai_draft_used` value. "Most" means at least 50% of a user's saved versions; "heavy" additionally requires #{@heavy_ai_minimum}+ AI-assisted versions.
      * Pages/week counts distinct user-page pairs in each UTC calendar week. It measures pages touched, not final page completions.
      * Retention counts all collection-edit deeds, while adoption and productivity require a saved page version. The latter therefore exclude contributions such as article, metadata, and review deeds that do not save a page version; their user denominators will be smaller.
      * The full AI-enabled cohort is selected from C and is not longitudinally balanced. Productivity is therefore also reported for collections active in all three periods and for collections active in both B and C. "Active" means at least one non-owner collection-edit deed in the period.
    MD
  end

  def retention
    lines = ['## Retention', '', '| Collection scope | Participant scope | A | B | C | A returning in B | B returning in C |', '|---|---:|---:|---:|---:|---:|---:|']
    { 'All collections' => @contributions, 'AI-enabled collections' => @eligible_contributions }.each do |scope_name, counts|
      SCOPES.each do |label, minimum|
        sets = counts.transform_values { |values| values.select { |_id, count| count >= minimum }.keys.to_set }
        lines << "| #{scope_name} | #{label} | #{sets['A'].size} | #{sets['B'].size} | #{sets['C'].size} | #{intersection(sets, 'A', 'B')} | #{intersection(sets, 'B', 'C')} |"
      end
    end
    lines.join("\n")
  end

  def adoption
    c_stats = user_version_stats(@versions['C'])
    bands = adoption_bands(c_stats)
    debug "Adoption intermediary results: #{bands.transform_values(&:size).map { |label, count| "#{label}=#{count}" }.join(', ')}"
    lines = ['## Adoption', '', "#{c_stats.count { |_id, s| s[:ai].positive? }} non-owner users used an AI Draft in C.", '', '| Adoption band | Users | Percent |', '|---|---:|---:|']
    bands.each { |label, ids| lines << "| #{label} | #{ids.size} | #{percent(ids.size, c_stats.size)} |" }
    lines += ['', transition_table('B', 'C', include_ai: true), '', transition_table('A', 'B', include_ai: false)]
    lines += ['', '> Retention and adoption/productivity have different denominators: retention includes all collection-edit deeds, while this section includes only users with saved page versions.']
    lines.join("\n")
  end

  def transition_table(from, to, include_ai:)
    from_pairs = user_collections(@versions[from])
    to_pairs = user_collections(@versions[to])
    cohort = from_pairs.keys.to_set
    same = cohort.count { |id| (from_pairs[id] & to_pairs.fetch(id, Set.new)).any? }
    other = cohort.count { |id| to_pairs.key?(id) && (from_pairs[id] & to_pairs[id]).empty? }
    inactive = cohort.size - same - other
    debug "#{from}->#{to} switching (fixed AI-enabled collection set): cohort=#{cohort.size}, same=#{same}, " \
          "different=#{other}, inactive=#{inactive}"
    title = "### #{from} to #{to} collection behavior"
    rows = [title, '', "Cohort: #{cohort.size} users active in #{from} on the fixed AI-enabled collection set.", '', '| Outcome | Users | Percent |', '|---|---:|---:|', "| Continued on at least one same collection | #{same} | #{percent(same, cohort.size)} |", "| Used only different collections | #{other} | #{percent(other, cohort.size)} |", "| No activity in this collection scope | #{inactive} | #{percent(inactive, cohort.size)} |"]
    if include_ai
      ai_users = user_version_stats(@versions[to]).select { |id, s| cohort.include?(id) && s[:ai].positive? }.size
      continuing = cohort.count { |id| to_pairs.key?(id) }
      rows += ['', "Among the #{continuing} cohort members active on an AI-enabled collection in #{to}, #{ai_users} used AI Drafts (#{percent(ai_users, continuing)}) and #{continuing - ai_users} ignored them (#{percent(continuing - ai_users, continuing)})."]
    end
    rows.join("\n")
  end

  def productivity
    all_periods = @active_eligible_collection_ids.values.reduce(:&)
    b_and_c = @active_eligible_collection_ids['B'] & @active_eligible_collection_ids['C']
    debug "Productivity panels: full=#{@eligible_collection_ids.size} collections, " \
          "active in A/B/C=#{all_periods.size}, active in B/C=#{b_and_c.size}"

    lines = ['## Productivity', '', '### Full C-selected AI-enabled collection cohort (unbalanced)', '', '> This cohort is selected using period C AI records and is projected backward. Changes may reflect collections entering or leaving the active portfolio, not a change in volunteer productivity.', '', '| Period | Users | Distinct page-weeks | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|']
    PERIODS.each_key { |label| lines << productivity_row(label, @versions[label]) }

    lines += ['', "### Balanced panel: #{all_periods.size} collections active in A, B, and C", '', '| Period | Users | Distinct page-weeks | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|']
    PERIODS.each_key do |label|
      lines << productivity_row(label, versions_for_collections(label, all_periods))
    end

    lines += ['', "### B/C panel: #{b_and_c.size} collections active in both B and C", '', '| Period | Users | Distinct page-weeks | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|']
    %w[B C].each do |label|
      lines << productivity_row(label, versions_for_collections(label, b_and_c))
    end

    c_stats = user_version_stats(@versions['C'])
    ai_ids = c_stats.select { |_id, s| s[:ai].positive? }.keys.to_set
    lines += ['', '### Period C by AI use', '', '| Group | Users | Distinct page-weeks | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|', productivity_row('Used AI Draft', @versions['C'].select { |row| ai_ids.include?(row[0]) }), productivity_row('Never used AI Draft', @versions['C'].reject { |row| ai_ids.include?(row[0]) }), '', 'For context, the all-user period B average appears in the preceding table.']
    lines.join("\n")
  end

  def productivity_row(label, rows)
    user_rows = rows.group_by(&:first)
    page_weeks = rows.map { |r| [r[0], r[1], r[3].to_date.cwyear, r[3].to_date.cweek] }.uniq.size
    user_weeks = rows.group_by { |r| [r[0], r[3].to_date.cweek, r[3].to_date.cwyear] }.size
    per_user_week = user_rows.values.map do |rows_for_user|
      page_week_count = rows_for_user.map { |r| [r[1], r[3].to_date.cwyear, r[3].to_date.cweek] }.uniq.size
      active_week_count = rows_for_user.map { |r| [r[3].to_date.cwyear, r[3].to_date.cweek] }.uniq.size
      page_week_count.to_f / active_week_count
    end
    debug "Productivity #{label}: users=#{user_rows.size}, distinct page-weeks=#{page_weeks}, " \
          "active user-weeks=#{user_weeks}, pages/user-week=#{ratio(page_weeks, user_weeks)}, " \
          "mean user pages/week=#{average(per_user_week)}"
    "| #{label} | #{user_rows.size} | #{page_weeks} | #{user_weeks} | #{ratio(page_weeks, user_weeks)} | #{average(per_user_week)} |"
  end

  def collections
    records = step('Loading eligible collection titles and owners') do
      Collection.includes(:owner).where(id: @eligible_collection_ids).order(:title).to_a
    end
    lines = ['## Qualitative: eligible collections', '', '| Collection | Owner institution | AI records in C | Active A | Active B | Active C |', '|---|---|---:|:---:|:---:|:---:|']
    counts = step('Counting period C AI transcription records by collection') do
      AiTranscription.joins(page: :work).where(created_at: PERIODS['C'].starts_at...PERIODS['C'].ends_at, works: { collection_id: @eligible_collection_ids }).group('works.collection_id').count
    end
    debug "Eligible collection intermediary results: #{records.map { |record| "#{record.id}=#{counts[record.id]}" }.join(', ')}"
    records.each { |c| lines << "| #{escape(c.title)} | #{escape(c.owner&.display_name)} | #{counts[c.id]} | #{yes(@active_eligible_collection_ids['A'].include?(c.id))} | #{yes(@active_eligible_collection_ids['B'].include?(c.id))} | #{yes(@active_eligible_collection_ids['C'].include?(c.id))} |" }
    lines.join("\n")
  end

  def survey_candidates
    stats = user_version_stats(@versions['C'])
    b_users = @versions['B'].map(&:first).to_set
    attempted = stats.select { |_id, s| (1..2).cover?(s[:ai]) && s[:subsequent_manual_saves].positive? }.keys
    heavy = stats.select { |_id, s| s[:ai] >= @heavy_ai_minimum && s[:ai].to_f / s[:total] >= 0.5 }.keys
    groups = { 'Tried once or twice, then continued without AI' => attempted, 'Heavy AI users with pre-AI experience' => heavy.select { |id| b_users.include?(id) }, 'New heavy AI users' => heavy.reject { |id| b_users.include?(id) } }
    debug "Survey candidate intermediary results: #{groups.transform_values(&:size).map { |label, count| "#{label}=#{count}" }.join(', ')}"
    lines = ['## Qualitative: survey candidates', '', '> **Sensitive:** This section contains contact information. Store and share the report appropriately.']
    users = step("Loading contact details for #{groups.values.flatten.uniq.size} survey candidates") do
      User.where(id: groups.values.flatten.uniq).index_by(&:id)
    end
    groups.each do |label, ids|
      lines += ['', "### #{label}", '']
      if label == 'Tried once or twice, then continued without AI'
        lines += ['| Display name | Email | First AI date | Last AI date | Subsequent manual saves | Subsequent active days | AI saves C | All saves C |', '|---|---|---|---|---:|---:|---:|---:|']
      else
        lines += ['| Display name | Email | AI saves C | All saves C |', '|---|---|---:|---:|']
      end
      ids.sort_by { |id| users[id]&.display_name.to_s.downcase }.each do |id|
        if label == 'Tried once or twice, then continued without AI'
          lines << "| #{escape(users[id]&.display_name)} | #{escape(users[id]&.email)} | #{date(stats[id][:first_ai])} | #{date(stats[id][:last_ai])} | #{stats[id][:subsequent_manual_saves]} | #{stats[id][:subsequent_active_days]} | #{stats[id][:ai]} | #{stats[id][:total]} |"
        else
          lines << "| #{escape(users[id]&.display_name)} | #{escape(users[id]&.email)} | #{stats[id][:ai]} | #{stats[id][:total]} |"
        end
      end
    end
    lines.join("\n")
  end

  def user_version_stats(rows)
    rows.group_by(&:first).transform_values do |user_rows|
      ai_rows = user_rows.select { |row| row[4] }
      non_ai_rows = user_rows.reject { |row| row[4] }
      first_ai = ai_rows.map { |r| r[3] }.min
      last_ai = ai_rows.map { |r| r[3] }.max
      subsequent_manual_rows = last_ai ? non_ai_rows.select { |row| row[3] > last_ai } : []
      {
        total: user_rows.size,
        ai: ai_rows.size,
        first_ai: first_ai,
        last_ai: last_ai,
        subsequent_manual_saves: subsequent_manual_rows.size,
        subsequent_active_days: subsequent_manual_rows.map { |row| row[3].to_date }.uniq.size
      }
    end
  end

  def adoption_bands(stats)
    { 'Never' => stats.select { |_id, s| s[:ai].zero? }.keys, 'Tried once or twice' => stats.select { |_id, s| (1..2).cover?(s[:ai]) }.keys, 'Adopted for most work' => stats.select { |_id, s| s[:ai] >= 3 && s[:ai].to_f / s[:total] >= 0.5 }.keys, 'Some use, but less than half' => stats.select { |_id, s| s[:ai] >= 3 && s[:ai].to_f / s[:total] < 0.5 }.keys }
  end

  def user_collections(rows)
    rows.each_with_object(Hash.new { |h, k| h[k] = Set.new }) { |row, result| result[row[0]] << row[2] }
  end

  def versions_for_collections(label, collection_ids)
    @versions[label].select { |row| collection_ids.include?(row[2]) }
  end

  def debug_contributions(label, scope, counts)
    thresholds = SCOPES.map do |name, minimum|
      "#{name}=#{counts.count { |_user_id, count| count >= minimum }}"
    end
    debug "Period #{label}, #{scope}: #{counts.size} participant count records (#{thresholds.join(', ')})"
  end

  def step(description)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    debug "START #{description}"
    result = yield
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    debug format('DONE  %s (%.2fs)', description, elapsed)
    result
  rescue StandardError => e
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    debug format('ERROR %s after %.2fs: %s: %s', description, elapsed, e.class, e.message)
    raise
  end

  def debug(message)
    puts "[#{Time.current.utc.iso8601}] [AI volunteer report] #{message}"
  end

  def list(values, limit: 50)
    return values.join(', ') if values.size <= limit

    "#{values.first(limit).join(', ')}, ... (#{values.size - limit} more)"
  end

  def intersection(sets, left, right) = (sets[left] & sets[right]).size
  def percent(value, total) = total.zero? ? 'n/a' : "#{(100.0 * value / total).round(1)}%"
  def ratio(numerator, denominator) = denominator.zero? ? 'n/a' : (numerator.to_f / denominator).round(2)
  def average(values) = values.empty? ? 'n/a' : (values.sum / values.size).round(2)
  def yes(value) = value ? 'Yes' : 'No'
  def date(value) = value&.to_date&.iso8601.to_s
  def escape(value) = value.to_s.gsub('|', '\\|').gsub(/\r?\n/, ' ')
end

output = ENV.fetch('OUTPUT', Rails.root.join('tmp/ai_volunteer_behavior_report.md').to_s)
minimum = ENV.fetch('AI_COLLECTION_MINIMUM', AiVolunteerBehaviorReport::AI_COLLECTION_MINIMUM).to_i
heavy_minimum = ENV.fetch('HEAVY_AI_MINIMUM', AiVolunteerBehaviorReport::HEAVY_AI_MINIMUM).to_i

path = AiVolunteerBehaviorReport.new(
  output: output,
  ai_collection_minimum: minimum,
  heavy_ai_minimum: heavy_minimum
).call
puts "Wrote #{path}"
