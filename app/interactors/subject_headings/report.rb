require 'csv'

class SubjectHeadings::Report
  HEADERS = %w[heading uri suggested_heading suggested_uri result rationale].freeze

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
    exact = hits.select { |h| h['aLabel'] == row['heading'] }
    return suggestion(row, exact, 'exact_match', 'LC returned the same authorized label. Uploaded identifiers are preserved; review any different suggested URI.') if exact.any?
    variants = hits.select { |h| h['suggestLabel'] == row['heading'] }
    return suggestion(row, variants, 'variant_label', 'LC matched a suggested label to a different authorized label; review before adopting.') if variants.any?
    if hits.empty?
      complex = row['heading'].include?('--')
      return row.merge('result' => complex ? 'complex_heading_not_fully_verified' : 'no_match_found',
        'rationale' => complex ? 'No complete-string authority found. Constructed subdivisions may be legitimate without one authority URI.' : 'No match found in this limited search. Local terms and unmatched headings remain usable; this does not mean invalid.')
    end
    suggestion(row, hits, 'possible_match', 'LC returned keyword candidates. This is a possible match, not confirmation that the uploaded heading is authorized.')
  end

  def self.suggestion(row, hits, result, rationale)
    if hits.size > 1
      row.merge('result' => 'multiple_possible_matches', 'rationale' => "Ambiguous: #{hits.first(5).map { |h| "#{h['aLabel']} (#{h['uri']})" }.join('; ')}. Review candidates; no replacement selected.")
    else
      row.merge('suggested_heading' => hits.first['aLabel'], 'suggested_uri' => hits.first['uri'], 'result' => result, 'rationale' => rationale)
    end
  end
end
