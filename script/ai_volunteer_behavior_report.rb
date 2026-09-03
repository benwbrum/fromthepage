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
    @eligible_collection_ids = eligible_collection_ids
    @contributions = PERIODS.transform_values { |period| contribution_counts(period) }
    @eligible_contributions = PERIODS.transform_values do |period|
      contribution_counts(period, collection_ids: @eligible_collection_ids)
    end
    @all_user_collections = PERIODS.transform_values { |period| deed_user_collections(period) }
    @versions = PERIODS.transform_values { |period| version_rows(period, collection_ids: @eligible_collection_ids) }

    FileUtils.mkdir_p(File.dirname(@output))
    File.write(@output, render)
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
    sections = [header, retention, adoption, productivity, collections, survey_candidates]
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
    lines = ['## Adoption', '', "#{c_stats.count { |_id, s| s[:ai].positive? }} non-owner users used an AI Draft in C.", '', '| Adoption band | Users | Percent |', '|---|---:|---:|']
    bands.each { |label, ids| lines << "| #{label} | #{ids.size} | #{percent(ids.size, c_stats.size)} |" }
    lines += ['', transition_table('B', 'C', include_ai: true), '', transition_table('A', 'B', include_ai: false, pairs: @all_user_collections, scope_label: 'all collections')]
    lines.join("\n")
  end

  def transition_table(from, to, include_ai:, pairs: nil, scope_label: 'fixed AI-enabled collection set')
    from_pairs = pairs ? pairs[from] : user_collections(@versions[from])
    to_pairs = pairs ? pairs[to] : user_collections(@versions[to])
    cohort = from_pairs.keys.to_set
    same = cohort.count { |id| (from_pairs[id] & to_pairs.fetch(id, Set.new)).any? }
    other = cohort.count { |id| to_pairs.key?(id) && (from_pairs[id] & to_pairs[id]).empty? }
    inactive = cohort.size - same - other
    title = "### #{from} to #{to} collection behavior"
    rows = [title, '', "Cohort: #{cohort.size} users active in #{from} on #{scope_label}.", '', '| Outcome | Users | Percent |', '|---|---:|---:|', "| Continued on at least one same collection | #{same} | #{percent(same, cohort.size)} |", "| Used only different collections | #{other} | #{percent(other, cohort.size)} |", "| No activity in this collection scope | #{inactive} | #{percent(inactive, cohort.size)} |"]
    if include_ai
      ai_users = user_version_stats(@versions[to]).select { |id, s| cohort.include?(id) && s[:ai].positive? }.size
      continuing = cohort.count { |id| to_pairs.key?(id) }
      rows += ['', "Among the #{continuing} cohort members active on an AI-enabled collection in #{to}, #{ai_users} used AI Drafts (#{percent(ai_users, continuing)}) and #{continuing - ai_users} ignored them (#{percent(continuing - ai_users, continuing)})."]
    end
    rows.join("\n")
  end

  def productivity
    lines = ['## Productivity', '', '| Period | Users | Distinct pages | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|']
    PERIODS.each_key { |label| lines << productivity_row(label, @versions[label]) }
    c_stats = user_version_stats(@versions['C'])
    ai_ids = c_stats.select { |_id, s| s[:ai].positive? }.keys.to_set
    lines += ['', '### Period C by AI use', '', '| Group | Users | Distinct pages | Active user-weeks | Pages / active user-week | Mean user pages/week |', '|---|---:|---:|---:|---:|---:|', productivity_row('Used AI Draft', @versions['C'].select { |row| ai_ids.include?(row[0]) }), productivity_row('Never used AI Draft', @versions['C'].reject { |row| ai_ids.include?(row[0]) }), '', 'For context, the all-user period B average appears in the preceding table.']
    lines.join("\n")
  end

  def productivity_row(label, rows)
    user_pages = rows.group_by(&:first).transform_values { |r| r.map { |x| x[1] }.uniq.size }
    user_weeks = rows.group_by { |r| [r[0], r[3].to_date.cweek, r[3].to_date.cwyear] }.size
    per_user_week = rows.group_by(&:first).values.map do |user_rows|
      user_rows.map { |r| r[1] }.uniq.size.to_f / user_rows.map { |r| [r[3].to_date.cweek, r[3].to_date.cwyear] }.uniq.size
    end
    "| #{label} | #{user_pages.size} | #{user_pages.values.sum} | #{user_weeks} | #{ratio(user_pages.values.sum, user_weeks)} | #{average(per_user_week)} |"
  end

  def collections
    active = PERIODS.transform_values { |p| non_owner_deeds(p, collection_ids: @eligible_collection_ids).distinct.pluck(:collection_id).to_set }
    records = Collection.includes(:owner).where(id: @eligible_collection_ids).order(:title)
    lines = ['## Qualitative: eligible collections', '', '| Collection | Owner institution | AI records in C | Active A | Active B | Active C |', '|---|---|---:|:---:|:---:|:---:|']
    counts = AiTranscription.joins(page: :work).where(created_at: PERIODS['C'].starts_at...PERIODS['C'].ends_at, works: { collection_id: @eligible_collection_ids }).group('works.collection_id').count
    records.each { |c| lines << "| #{escape(c.title)} | #{escape(c.owner&.display_name)} | #{counts[c.id]} | #{yes(active['A'].include?(c.id))} | #{yes(active['B'].include?(c.id))} | #{yes(active['C'].include?(c.id))} |" }
    lines.join("\n")
  end

  def survey_candidates
    stats = user_version_stats(@versions['C'])
    b_users = @versions['B'].map(&:first).to_set
    attempted = stats.select { |_id, s| (1..2).cover?(s[:ai]) && s[:last_non_ai] && s[:last_non_ai] > s[:last_ai] }.keys
    heavy = stats.select { |_id, s| s[:ai] >= @heavy_ai_minimum && s[:ai].to_f / s[:total] >= 0.5 }.keys
    groups = { 'Tried once or twice, then continued without AI' => attempted, 'Heavy AI users with pre-AI experience' => heavy.select { |id| b_users.include?(id) }, 'New heavy AI users' => heavy.reject { |id| b_users.include?(id) } }
    lines = ['## Qualitative: survey candidates', '', '> **Sensitive:** This section contains contact information. Store and share the report appropriately.']
    users = User.where(id: groups.values.flatten.uniq).index_by(&:id)
    groups.each do |label, ids|
      lines += ['', "### #{label}", '', '| Display name | Email | AI saves C | All saves C |', '|---|---|---:|---:|']
      ids.sort_by { |id| users[id]&.display_name.to_s.downcase }.each do |id|
        lines << "| #{escape(users[id]&.display_name)} | #{escape(users[id]&.email)} | #{stats[id][:ai]} | #{stats[id][:total]} |"
      end
    end
    lines.join("\n")
  end

  def user_version_stats(rows)
    rows.group_by(&:first).transform_values do |user_rows|
      ai_rows = user_rows.select { |row| row[4] }
      non_ai_rows = user_rows.reject { |row| row[4] }
      { total: user_rows.size, ai: ai_rows.size, last_ai: ai_rows.map { |r| r[3] }.max, last_non_ai: non_ai_rows.map { |r| r[3] }.max }
    end
  end

  def adoption_bands(stats)
    { 'Never' => stats.select { |_id, s| s[:ai].zero? }.keys, 'Tried once or twice' => stats.select { |_id, s| (1..2).cover?(s[:ai]) }.keys, 'Adopted for most work' => stats.select { |_id, s| s[:ai] >= 3 && s[:ai].to_f / s[:total] >= 0.5 }.keys, 'Some use, but less than half' => stats.select { |_id, s| s[:ai] >= 3 && s[:ai].to_f / s[:total] < 0.5 }.keys }
  end

  def user_collections(rows)
    rows.each_with_object(Hash.new { |h, k| h[k] = Set.new }) { |row, result| result[row[0]] << row[2] }
  end

  def deed_user_collections(period)
    non_owner_deeds(period).distinct.pluck(:user_id, :collection_id).each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(user_id, collection_id), result|
      result[user_id] << collection_id
    end
  end

  def intersection(sets, left, right) = (sets[left] & sets[right]).size
  def percent(value, total) = total.zero? ? 'n/a' : "#{(100.0 * value / total).round(1)}%"
  def ratio(numerator, denominator) = denominator.zero? ? 'n/a' : (numerator.to_f / denominator).round(2)
  def average(values) = values.empty? ? 'n/a' : (values.sum / values.size).round(2)
  def yes(value) = value ? 'Yes' : 'No'
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
