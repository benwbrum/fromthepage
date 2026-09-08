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
  SUBSTANTIAL_ELIGIBLE_PAGES = 100
  IMPLAUSIBLE_WEEKLY_PAGES = 500
  BOOTSTRAP_SAMPLES = 2_000

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

    @ai_available_at_by_page = step('Reconstructing page-level AI availability before period C saves') do
      ai_available_at_by_page(@versions['C'].map { |row| row[1] }.uniq)
    end
    debug "Reconstructed prior AI availability for #{@ai_available_at_by_page.size} period C pages"

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

  def ai_available_at_by_page(page_ids)
    AiTranscription.where(page_id: page_ids, status: 'finished')
      .where(<<~SQL.squish)
        (source_text IS NOT NULL AND TRIM(source_text) != '')
        OR (transcription_json IS NOT NULL AND TRIM(transcription_json) NOT IN ('', '{}', '[]', 'null'))
      SQL
      .group(:page_id).minimum(:updated_at)
  end

  def render
    sections = []
    {
      'methodology' => :header,
      'retention' => :retention,
      'adoption and switching' => :adoption,
      'page-level AI eligibility' => :page_ai_eligibility,
      'productivity' => :productivity,
      'within-person productivity' => :within_person_productivity,
      'longitudinal B-to-C productivity' => :longitudinal_productivity,
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
      * Suspicious-behavior counts for heavy AI users include records created during period C across all collections, grouped by behavior type. They are signals for review, not findings that abuse occurred.
      * Exact historical AI eligibility cannot be reconstructed: collection configuration (`ai_draft_disabled`, entry type, and related UI conditions) is not versioned, and legacy filesystem drafts have no queryable availability timestamp. The conservative database proxy used below requires a currently-finished `ai_transcriptions` record with nonblank text/JSON whose `updated_at` is no later than the human save. Current collection settings are deliberately not projected backward. This proxy can undercount drafts (especially records updated later or legacy files) and can still overstate exposure if a collection had AI disabled at the time.
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

  def page_ai_eligibility
    rows = @versions['C']
    row_categories = rows.group_by { |row| eligibility_category(row) }
    pair_categories = eligibility_pair_categories(rows)
    eligible_pairs = pair_categories.count { |_pair, category| %i[eligible_ai eligible_manual].include?(category) }
    eligible_saves = row_categories.fetch(:eligible_ai, []).size + row_categories.fetch(:eligible_manual, []).size
    all_users = rows.map(&:first).uniq
    eligible_users = pair_categories.filter_map { |(user_id, _page_id), category| user_id if %i[eligible_ai eligible_manual].include?(category) }.uniq
    users_with_any_ai_save = rows.filter_map { |row| row[0] if row[4] }.uniq
    eligible_non_users = eligible_users - users_with_any_ai_save

    labels = {
      eligible_ai: 'Eligible, AI used', eligible_manual: 'Eligible, manual',
      not_eligible: 'Not eligible', anomaly: 'Apparent anomaly'
    }
    lines = ['## Page-level AI eligibility in C', '', '> **Historical reconstruction limitation:** exact UI availability is not stored. Eligibility below is the conservative finished-and-usable-record proxy described in Method; current collection settings are not used.', '', 'Denominator: all non-owner saved page versions in C in the fixed AI-enabled collection cohort. Distinct user-page categories are mutually exclusive; apparent anomaly takes precedence if a pair has conflicting saves.', '', '| AI eligibility / use | Saved versions | Distinct user-pages | Users | Percent of eligible user-pages |', '|---|---:|---:|---:|---:|']
    labels.each do |category, label|
      category_rows = row_categories.fetch(category, [])
      category_pairs = pair_categories.count { |_pair, value| value == category }
      denominator = %i[eligible_ai eligible_manual].include?(category) ? percent(category_pairs, eligible_pairs) : 'n/a'
      lines << "| #{label} | #{category_rows.size} | #{category_pairs} | #{category_rows.map(&:first).uniq.size} | #{denominator} |"
    end
    lines += [
      '', "Eligible saves were #{percent(eligible_saves, rows.size)} of all #{rows.size} C saves in the fixed AI-enabled collection cohort; eligible user-page pairs were #{percent(eligible_pairs, pair_categories.size)} of all #{pair_categories.size} distinct user-page pairs.",
      '', "#{eligible_users.size} of #{all_users.size} contributors (#{percent(eligible_users.size, all_users.size)}) encountered at least one proxy-eligible page. AI was used on #{pair_categories.count { |_pair, category| category == :eligible_ai }} of #{eligible_pairs} eligible user-page pairs (#{percent(pair_categories.count { |_pair, category| category == :eligible_ai }, eligible_pairs)}).",
      '', "#{eligible_non_users.size} of #{eligible_users.size} eligible contributors (#{percent(eligible_non_users.size, eligible_users.size)}) had no AI-assisted save at all in C."
    ]
    lines += ['', eligible_share_distribution(pair_categories), '', eligibility_by_collection(pair_categories)]
    debug "Page eligibility: eligible_saves=#{eligible_saves}/#{rows.size}, eligible_pairs=#{eligible_pairs}/#{pair_categories.size}, anomalies=#{row_categories.fetch(:anomaly, []).size}"
    lines.join("\n")
  end

  def eligible_share_distribution(pair_categories)
    by_user = pair_categories.group_by { |(user_id, _page_id), _category| user_id }
    shares = by_user.filter_map do |_user_id, pairs|
      eligible = pairs.count { |_pair, category| %i[eligible_ai eligible_manual].include?(category) }
      next if eligible < 10

      pairs.count { |_pair, category| category == :eligible_ai }.to_f / eligible
    end
    buckets = [['0%', 0.0, 0.0], ['1–24%', 0.0, 0.25], ['25–49%', 0.25, 0.5], ['50–74%', 0.5, 0.75], ['75–99%', 0.75, 1.0], ['100%', 1.0, 1.0]]
    lines = ["### AI-use share for contributors with 10+ eligible user-page pairs (n=#{shares.size})", '', "Median #{percentage_number(percentile(shares, 0.5))}; 25th percentile #{percentage_number(percentile(shares, 0.25))}; 75th percentile #{percentage_number(percentile(shares, 0.75))}.", '', '| AI share | Contributors | Percent |', '|---|---:|---:|']
    buckets.each do |label, low, high|
      count = shares.count { |share| low == high ? share == low : share >= low && share < high }
      count -= shares.count(&:zero?) if label == '1–24%'
      count = shares.count(&:zero?) if label == '0%'
      lines << "| #{label} | #{count} | #{percent(count, shares.size)} |"
    end
    lines.join("\n")
  end

  def eligibility_by_collection(pair_categories)
    collection_by_page = @versions['C'].to_h { |row| [row[1], row[2]] }
    by_collection = pair_categories.group_by { |(_user_id, page_id), _category| collection_by_page[page_id] }
    results = by_collection.map do |collection_id, pairs|
      eligible = pairs.select { |_pair, category| %i[eligible_ai eligible_manual].include?(category) }
      ai = eligible.count { |_pair, category| category == :eligible_ai }
      [collection_id, eligible.map { |(user_id, _page_id), _category| user_id }.uniq.size, eligible.size, ai]
    end
    substantial = results.select { |_collection_id, _users, pages, _ai| pages >= SUBSTANTIAL_ELIGIBLE_PAGES }.sort_by { |row| -row[2] }
    names = Collection.where(id: results.map(&:first)).pluck(:id, :title).to_h
    low_exposure = results.count { |_collection_id, _users, pages, _ai| pages.between?(1, 9) }
    zero_exposure = @eligible_collection_ids.size - results.count { |_collection_id, _users, pages, _ai| pages.positive? }
    lines = ['### Eligibility and adoption by collection', '', "#{low_exposure + zero_exposure} of #{@eligible_collection_ids.size} C-selected AI-enabled collections had fewer than 10 eligible volunteer user-page pairs, including #{zero_exposure} with none. This quantifies how much the collection-level definition can overstate actual volunteer exposure.", '', "The table includes all #{substantial.size} collections with at least #{SUBSTANTIAL_ELIGIBLE_PAGES} eligible user-page pairs; collections below that denominator are excluded.", '', '| Collection | Eligible users | Eligible user-pages | AI-assisted user-pages | AI adoption |', '|---|---:|---:|---:|---:|']
    substantial.each do |collection_id, users, eligible, ai|
      lines << "| #{escape(names[collection_id])} | #{users} | #{eligible} | #{ai} | #{percent(ai, eligible)} |"
    end
    lines.join("\n")
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

  def within_person_productivity
    week_rows = contributor_weeks(@versions['C'])
    qualifying = paired_entities(week_rows)
    top_cutoff = percentile(total_pages_by_user(week_rows).values, 0.99) || 0
    trimmed_ids = qualifying.keys.reject { |user_id| total_pages_by_user(week_rows)[user_id] > top_cutoff }.to_set
    trimmed = qualifying.select { |user_id, _stats| trimmed_ids.include?(user_id) }

    same_collection_rows = contributor_weeks(@versions['C'], include_collection: true)
    same_collection = paired_entities(same_collection_rows)

    week_values = week_rows.values
    manual_weeks = week_values.count { |values| values[:mode] == :manual }
    ai_weeks = week_values.count { |values| values[:mode] == :ai }
    majority_weeks = week_values.count { |values| values[:mode] == :ai && values[:ai_share] >= 0.5 }
    ineligible_weeks = week_values.count { |values| values[:mode] == :ineligible }
    lines = ['## Within-person productivity during C', '', 'Contributor-week denominator: all non-owner C saves in the fixed AI-enabled cohort. Pages are distinct within each user and UTC calendar week.', '', '| Week classification | Contributor-weeks | Percent of eligible contributor-weeks |', '|---|---:|---:|', "| Eligible manual-only | #{manual_weeks} | #{percent(manual_weeks, manual_weeks + ai_weeks)} |", "| AI-using | #{ai_weeks} | #{percent(ai_weeks, manual_weeks + ai_weeks)} |", "| ↳ AI-majority (at least 50% of eligible pages) | #{majority_weeks} | #{percent(majority_weeks, manual_weeks + ai_weeks)} |", "| No AI-eligible page (excluded from paired comparison) | #{ineligible_weeks} | n/a |", '', 'Primary paired denominator: contributors with at least one proxy-eligible manual-only week and at least one AI-using week. Weeks with no proxy-eligible pages are excluded. Weekly productivity is total distinct pages touched in the classified active week.', '', paired_productivity_table('All qualifying contributors', qualifying), '', "The top-1% sensitivity excludes contributors above #{top_cutoff.to_i} distinct C page-weeks (calculated among all C contributors in this cohort).", '', paired_productivity_table('Excluding the top 1% by total C page activity', trimmed), '', '### Same-user, same-collection sensitivity', '', 'Denominator: user-collection pairs with at least one eligible manual-only week and at least one AI-using week in that same collection.', '', paired_productivity_table('Qualifying user-collection pairs', same_collection)]
    anomaly_count = @versions['C'].count { |row| eligibility_category(row) == :anomaly }
    isolated_users = isolated_ai_users
    implausible = week_rows.count { |_key, values| values[:total_pages] > IMPLAUSIBLE_WEEKLY_PAGES }
    lines += ['', findings_and_caveats(qualifying, same_collection, anomaly_count, isolated_users, implausible)]
    lines.join("\n")
  end

  def contributor_weeks(rows, include_collection: false)
    grouped = rows.group_by do |row|
      date = row[3].to_date
      include_collection ? [row[0], row[2], date.cwyear, date.cweek] : [row[0], date.cwyear, date.cweek]
    end
    grouped.transform_values do |week_rows|
      page_rows = week_rows.group_by { |row| row[1] }
      page_categories = page_rows.transform_values { |values| eligibility_pair_category(values) }
      eligible = page_categories.count { |_page, category| %i[eligible_ai eligible_manual].include?(category) }
      ai = page_categories.count { |_page, category| category == :eligible_ai }
      {
        total_pages: page_rows.size,
        eligible_pages: eligible,
        ai_pages: ai,
        manual_pages: page_categories.count { |_page, category| category == :eligible_manual },
        ai_share: eligible.zero? ? nil : ai.to_f / eligible,
        mode: ai.positive? ? :ai : (eligible.positive? ? :manual : :ineligible)
      }
    end
  end

  def paired_entities(week_rows)
    # A user-week key has three elements and a user-collection-week key has four.
    entity_index = week_rows.group_by { |key, _values| key.size == 3 ? key[0] : key.first(2) }
    entity_index.filter_map do |entity, observations|
      manual = observations.filter_map { |_key, values| values[:total_pages] if values[:mode] == :manual }
      ai = observations.filter_map { |_key, values| values[:total_pages] if values[:mode] == :ai }
      next if manual.empty? || ai.empty?

      manual_rate = manual.sum.to_f / manual.size
      ai_rate = ai.sum.to_f / ai.size
      [entity, { manual_rate: manual_rate, ai_rate: ai_rate, difference: ai_rate - manual_rate, percent_change: 100.0 * (ai_rate - manual_rate) / manual_rate, manual_weeks: manual.size, ai_weeks: ai.size }]
    end.to_h
  end

  def paired_productivity_table(title, entities)
    values = entities.values
    manual = values.map { |stats| stats[:manual_rate] }
    ai = values.map { |stats| stats[:ai_rate] }
    differences = values.map { |stats| stats[:difference] }
    percent_changes = values.map { |stats| stats[:percent_change] }
    ci = bootstrap_median_ci(differences)
    increasing = percent_changes.count { |change| change > 10 }
    decreasing = percent_changes.count { |change| change < -10 }
    unchanged = values.size - increasing - decreasing
    lines = ["### #{title}", '', '| Measure | Manual-only weeks | AI-using weeks | Within-person change |', '|---|---:|---:|---:|', "| Contributors/pairs | #{values.size} | #{values.size} | #{values.size} |"]
    { 'Median pages / active week' => 0.5, '25th percentile' => 0.25, '75th percentile' => 0.75, '90th percentile' => 0.9 }.each do |label, quantile|
      lines << "| #{label} | #{number(percentile(manual, quantile))} | #{number(percentile(ai, quantile))} | #{signed_number(percentile(differences, quantile))} |"
    end
    lines.insert(6, "| Mean pages / active week | #{number(mean(manual))} | #{number(mean(ai))} | #{signed_number(mean(differences))} |")
    lines += ['', "Median within-person percentage change: #{signed_percentage(percentile(percent_changes, 0.5))}. Median paired absolute-change bootstrap 95% CI: #{number(ci[0])} to #{number(ci[1])} pages/week (#{BOOTSTRAP_SAMPLES} deterministic resamples).", '', "Using ±10% as essentially unchanged: #{percent(increasing, values.size)} increased, #{percent(decreasing, values.size)} decreased, and #{percent(unchanged, values.size)} were essentially unchanged.", '', "Observed weeks: #{values.sum { |stats| stats[:manual_weeks] }} manual-only and #{values.sum { |stats| stats[:ai_weeks] }} AI-using."]
    lines.join("\n")
  end

  def longitudinal_productivity
    panel = @active_eligible_collection_ids['B'] & @active_eligible_collection_ids['C']
    b_rows = versions_for_collections('B', panel)
    c_rows = versions_for_collections('C', panel)
    b_rates = user_productivity_rates(b_rows)
    c_rates = user_productivity_rates(c_rows)
    c_pairs = eligibility_pair_categories(c_rows)
    eligible_users = c_pairs.filter_map { |(user_id, _page_id), category| user_id if %i[eligible_ai eligible_manual].include?(category) }.to_set
    cohort = (b_rates.keys.to_set & c_rates.keys.to_set & eligible_users)
    groups = cohort.group_by { |user_id| longitudinal_adoption_group(user_id, c_rows, c_pairs) }
    group_labels = [
      'Never used AI despite eligible activity', 'Tried once or twice', 'Some AI use, under 50%',
      'AI for at least 50% of eligible work', "Heavy AI user (#{@heavy_ai_minimum}+ eligible AI saves)"
    ]
    lines = ['## Longitudinal B-to-C within-person comparison', '', "Denominator: #{cohort.size} contributors active in both B and C on the #{panel.size}-collection balanced B/C panel who encountered at least one proxy-eligible user-page pair in C. Rates are distinct page-weeks per active user-week.", '', '| C adoption group | Users | Median B pages/week | Median C pages/week | Median within-person change | Increasing |', '|---|---:|---:|---:|---:|---:|']
    group_labels.each do |label|
      user_ids = groups.fetch(label, [])
      changes = user_ids.map { |id| c_rates[id] - b_rates[id] }
      lines << "| #{label} | #{user_ids.size} | #{number(percentile(user_ids.map { |id| b_rates[id] }, 0.5))} | #{number(percentile(user_ids.map { |id| c_rates[id] }, 0.5))} | #{signed_number(percentile(changes, 0.5))} | #{percent(changes.count(&:positive?), changes.size)} |"
    end
    adopter_ids = groups.reject { |label, _ids| label == 'Never used AI despite eligible activity' }.values.flatten
    non_adopter_ids = groups.fetch('Never used AI despite eligible activity', [])
    adopter_change = mean(adopter_ids.map { |id| c_rates[id] - b_rates[id] })
    non_adopter_change = mean(non_adopter_ids.map { |id| c_rates[id] - b_rates[id] })
    descriptive_difference = adopter_change && non_adopter_change ? adopter_change - non_adopter_change : nil
    adopter_b_median = percentile(adopter_ids.map { |id| b_rates[id] }, 0.5)
    non_adopter_b_median = percentile(non_adopter_ids.map { |id| b_rates[id] }, 0.5)
    lines += ['', "Before period-C adoption behavior, eventual adopters had median B productivity of #{number(adopter_b_median)} pages/week versus #{number(non_adopter_b_median)} for eligible non-adopters. This directly describes baseline selection but does not explain its cause.", '', "Observational difference-in-differences-style description: mean B-to-C change among C AI adopters minus mean change among eligible C non-adopters = #{signed_number(descriptive_difference)} pages/week. This is not a causal treatment effect."]
    lines.join("\n")
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
    suspicious_counts = step("Counting period C suspicious behaviors for #{heavy.size} heavy AI users") do
      SuspiciousBehavior.where(user_id: heavy, created_at: PERIODS['C'].starts_at...PERIODS['C'].ends_at)
        .group(:user_id, :behavior_type).count
    end
    suspicious_total = suspicious_counts.values.sum
    suspicious_users = suspicious_counts.keys.map(&:first).uniq.size
    behavior_totals = suspicious_counts.each_with_object(Hash.new(0)) do |((_user_id, behavior_type), count), totals|
      totals[behavior_type] += count
    end
    suspicious_counts_by_user = suspicious_counts.each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |((user_id, behavior_type), count), result|
      result[user_id][behavior_type] = count
    end
    debug "Heavy AI suspicious-behavior results: records=#{suspicious_total}, users=#{suspicious_users}, " \
          "types=#{format_behavior_counts(behavior_totals)}"
    lines += ['', '### Suspicious behaviors among heavy AI users', '', "During period C, #{suspicious_total} suspicious-behavior records were created for #{suspicious_users} of the #{heavy.size} heavy AI users. Breakdown: #{format_behavior_counts(behavior_totals)}.", '', '> Suspicious-behavior records are automated or review signals and do not by themselves establish abuse.']
    users = step("Loading contact details for #{groups.values.flatten.uniq.size} survey candidates") do
      User.where(id: groups.values.flatten.uniq).index_by(&:id)
    end
    groups.each do |label, ids|
      lines += ['', "### #{label}", '']
      if label == 'Tried once or twice, then continued without AI'
        lines += ['| Display name | Email | First AI date | Last AI date | Subsequent manual saves | Subsequent active days | AI saves C | All saves C |', '|---|---|---|---|---:|---:|---:|---:|']
      else
        lines += ['| Display name | Email | AI saves C | All saves C | Suspicious behaviors C | Behavior types C |', '|---|---|---:|---:|---:|---|']
      end
      ids.sort_by { |id| users[id]&.display_name.to_s.downcase }.each do |id|
        if label == 'Tried once or twice, then continued without AI'
          lines << "| #{escape(users[id]&.display_name)} | #{escape(users[id]&.email)} | #{date(stats[id][:first_ai])} | #{date(stats[id][:last_ai])} | #{stats[id][:subsequent_manual_saves]} | #{stats[id][:subsequent_active_days]} | #{stats[id][:ai]} | #{stats[id][:total]} |"
        else
          user_behavior_counts = suspicious_counts_by_user[id]
          lines << "| #{escape(users[id]&.display_name)} | #{escape(users[id]&.email)} | #{stats[id][:ai]} | #{stats[id][:total]} | #{user_behavior_counts.values.sum} | #{escape(format_behavior_counts(user_behavior_counts))} |"
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

  def eligibility_category(row)
    available_at = @ai_available_at_by_page[row[1]]
    eligible = available_at && available_at <= row[3]
    return :eligible_ai if eligible && row[4]
    return :eligible_manual if eligible
    return :anomaly if row[4]

    :not_eligible
  end

  def eligibility_pair_categories(rows)
    rows.group_by { |row| [row[0], row[1]] }.transform_values { |pair_rows| eligibility_pair_category(pair_rows) }
  end

  def eligibility_pair_category(rows)
    categories = rows.map { |row| eligibility_category(row) }
    return :anomaly if categories.include?(:anomaly)
    return :eligible_ai if categories.include?(:eligible_ai)
    return :eligible_manual if categories.include?(:eligible_manual)

    :not_eligible
  end

  def user_productivity_rates(rows)
    rows.group_by(&:first).transform_values do |user_rows|
      page_weeks = user_rows.map { |row| [row[1], row[3].to_date.cwyear, row[3].to_date.cweek] }.uniq.size
      active_weeks = user_rows.map { |row| [row[3].to_date.cwyear, row[3].to_date.cweek] }.uniq.size
      page_weeks.to_f / active_weeks
    end
  end

  def longitudinal_adoption_group(user_id, rows, pair_categories)
    user_pairs = pair_categories.select { |(candidate_id, _page_id), category| candidate_id == user_id && %i[eligible_ai eligible_manual].include?(category) }
    ai_pairs = user_pairs.count { |_pair, category| category == :eligible_ai }
    ai_saves = rows.count { |row| row[0] == user_id && row[4] && eligibility_category(row) == :eligible_ai }
    share = ai_pairs.to_f / user_pairs.size
    return "Heavy AI user (#{@heavy_ai_minimum}+ eligible AI saves)" if ai_saves >= @heavy_ai_minimum
    return 'AI for at least 50% of eligible work' if share >= 0.5
    return 'Some AI use, under 50%' if ai_pairs >= 3
    return 'Tried once or twice' if ai_pairs.positive?

    'Never used AI despite eligible activity'
  end

  def total_pages_by_user(week_rows)
    week_rows.each_with_object(Hash.new(0)) do |(key, values), totals|
      totals[key[0]] += values[:total_pages]
    end
  end

  def isolated_ai_users
    stats = user_version_stats(@versions['C'])
    stats.count { |_user_id, values| values[:ai] == 1 && values[:total] >= 1_000 }
  end

  def findings_and_caveats(paired, same_collection, anomaly_count, isolated_users, implausible_weeks)
    paired_changes = paired.values.map { |stats| stats[:difference] }
    same_collection_changes = same_collection.values.map { |stats| stats[:difference] }
    eligible_pairs = eligibility_pair_categories(@versions['C']).count { |_pair, category| %i[eligible_ai eligible_manual].include?(category) }
    all_pairs = eligibility_pair_categories(@versions['C']).size
    top_users = total_pages_by_user(contributor_weeks(@versions['C'])).values.sort.reverse
    top_one_count = [(top_users.size * 0.01).ceil, 1].max
    top_one_share = top_users.empty? ? nil : top_users.first(top_one_count).sum.to_f / top_users.sum
    maximum_user_activity = top_users.first || 0
    maximum_week_activity = contributor_weeks(@versions['C']).values.map { |values| values[:total_pages] }.max || 0
    <<~MD.chomp
      ### Findings and caveats

      * Proxy-eligible exposure covered #{eligible_pairs} of #{all_pairs} C user-page pairs (#{percent(eligible_pairs, all_pairs)}); exact historical UI availability cannot be reconstructed.
      * Among #{paired.size} paired contributors, the median AI-week minus manual-week change was #{signed_number(percentile(paired_changes, 0.5))} pages/week. This is an association within people, not a causal estimate.
      * Among #{same_collection.size} qualifying user-collection pairs, the median within-collection change was #{signed_number(percentile(same_collection_changes, 0.5))} pages/week. Small samples are reported rather than relaxed.
      * The longitudinal section tests whether eventual adopters were already more productive in B; its descriptive difference must not be interpreted causally.
      * The top 1% of contributors account for #{percentage_number(top_one_share)} of C page-week activity. The largest contributor recorded #{maximum_user_activity} page-weeks and the largest user-week contained #{maximum_week_activity} pages. The trimmed paired table shows sensitivity to those contributors.
      * Anomaly checks found #{anomaly_count} AI-used saves before proxy availability, #{isolated_users} users with one AI save amid at least 1,000 total saves, and #{implausible_weeks} user-weeks above #{IMPLAUSIBLE_WEEKLY_PAGES} distinct pages. These require investigation rather than automatic exclusion.
      * Bulk AI generation is partly captured by the collection-exposure table: collections with many AI records but few eligible volunteer saves should not be treated as exposed volunteer projects. Generation provenance and historical collection settings are not sufficiently versioned for exact reconstruction.
    MD
  end

  def bootstrap_median_ci(values)
    return [nil, nil] if values.empty?

    random = Random.new(20_260_208)
    medians = Array.new(BOOTSTRAP_SAMPLES) do
      percentile(Array.new(values.size) { values[random.rand(values.size)] }, 0.5)
    end
    [percentile(medians, 0.025), percentile(medians, 0.975)]
  end

  def percentile(values, quantile)
    return nil if values.empty?

    sorted = values.sort
    position = quantile * (sorted.size - 1)
    lower = sorted[position.floor]
    upper = sorted[position.ceil]
    lower + ((upper - lower) * (position - position.floor))
  end

  def mean(values)
    values.empty? ? nil : values.sum.to_f / values.size
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

  def format_behavior_counts(counts)
    return 'none' if counts.empty?

    counts.sort_by { |behavior_type, _count| behavior_type }.map do |behavior_type, count|
      "#{behavior_type}=#{count}"
    end.join(', ')
  end

  def intersection(sets, left, right) = (sets[left] & sets[right]).size
  def percent(value, total) = total.zero? ? 'n/a' : "#{(100.0 * value / total).round(1)}%"
  def ratio(numerator, denominator) = denominator.zero? ? 'n/a' : (numerator.to_f / denominator).round(2)
  def average(values) = values.empty? ? 'n/a' : (values.sum / values.size).round(2)
  def number(value) = value.nil? ? 'n/a' : value.round(2)
  def signed_number(value) = value.nil? ? 'n/a' : format('%+.2f', value)
  def percentage_number(value) = value.nil? ? 'n/a' : "#{(value * 100).round(1)}%"
  def signed_percentage(value) = value.nil? ? 'n/a' : format('%+.1f%%', value)
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
