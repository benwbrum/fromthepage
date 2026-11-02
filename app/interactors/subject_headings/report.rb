require 'csv'

class SubjectHeadings::Report
  IMPORT_HEADERS = %w[heading uri suggested_heading suggested_uri result rationale].freeze
  HEADERS = (IMPORT_HEADERS + %w[authority_type candidate_uris]).freeze

  REUPLOAD_INSTRUCTIONS = 'Review the suggested headings and identifiers. To accept a suggestion, copy its value into the heading or uri column. Save the CSV and upload it again. Your current headings will not change until you upload a revised file.'.freeze

  def self.formula?(value)
    value.to_s.match?(/\A'*(?:[[:space:]\uFEFF]*[=+@-]|[\t\r\n])/)
  end

  def self.safe_cell(value)
    formula?(value) ? "'#{value}" : value
  end

  # Reverse the report's spreadsheet escape, including originally quoted formulas.
  def self.import_cell(value)
    value&.start_with?("'") && formula?(value[1..]) ? value[1..] : value
  end

  def self.generate(rows)
    "\uFEFF" + CSV.generate(row_sep: "\r\n") do |csv|
      csv << HEADERS
      rows.each { |row| csv << HEADERS.map { |key| safe_cell(row[key]) } }
    end
  end

  def self.result(row, hits)
    verified = hits.select { |hit| hit['evidence'] == 'authority' }
    exact = verified.select { |hit| hit['aLabel'] == row['heading'] }
    normalized = verified.select { |hit| SubjectHeadings::AuthorityLookup.normalize(hit['aLabel']) == SubjectHeadings::AuthorityLookup.normalize(row['heading']) }
    variants = verified.select do |hit|
      hit.fetch('variants', []).any? { |label| SubjectHeadings::AuthorityLookup.normalize(label) == SubjectHeadings::AuthorityLookup.normalize(row['heading']) }
    end
    matches, status, rationale = if exact.any?
      [exact, 'exact_match', "Matches an LC #{exact.first['authority_type'].downcase} authority."]
    elsif normalized.any?
      period_only = normalized.all? { |hit| hit['aLabel'].sub(/\.\z/, '') == row['heading'].sub(/\.\z/, '') }
      [normalized, 'formatting_suggestion', period_only ? 'Terminal period differs from authorized label.' : 'Spacing differs from authorized label.']
    elsif variants.any?
      [variants, 'variant_match', 'Documented variant of the authorized label.']
    else
      rationale = if hits.any? { |hit| hit['identifier_mismatch'] }
        'Supplied identifier has a different authorized label; review it.'
      elsif hits.any?
        'Related search results only; no equivalent authority verified.'
      elsif row['heading'].include?('--')
        'No standalone authority found; constructed subject strings may be valid.'
      else
        'No authority match found; local headings remain usable.'
      end
      return row.merge('result' => hits.empty? ? 'no_match_found' : 'possible_match', 'rationale' => rationale)
    end
    matches = matches.uniq { |hit| hit['uri'] }
    types = matches.map { |hit| hit['authority_type'] }.uniq
    if matches.size > 1
      status = 'multiple_authority_matches'
      rationale = types.size > 1 ? "Matching records found in both #{types.map(&:downcase).join(' and ')} vocabularies; review the records." : "Multiple #{types.first.downcase} authority records share this label; review the records."
    elsif types == ['Name'] && status == 'exact_match'
      status = 'possible_match'
      rationale = 'Matches an LC name authority; confirm that the person, organization or place is the intended subject.'
    end
    if hits.any? { |hit| hit['identifier_mismatch'] }
      rationale += ' Supplied identifier identifies a different authority.'
    end
    row.merge('result' => status, 'rationale' => rationale, 'authority_type' => types.join('; '),
      'suggested_heading' => matches.one? ? matches.first['aLabel'] : nil,
      'suggested_uri' => matches.one? ? matches.first['uri'] : nil,
      'candidate_uris' => matches.size > 1 ? matches.map { |hit| hit['uri'] }.join('; ') : nil)
  end
end
