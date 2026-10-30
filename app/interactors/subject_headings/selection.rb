class SubjectHeadings::Selection
  class InvalidSelection < ArgumentError; end
  # Store snapshots, never option IDs: inventories are replaceable.
  def self.resolve(field:, values:, previous: [])
    values = Array(values).reject(&:blank?)
    raise InvalidSelection, 'Too many selected subject headings.' if values.length > 200

    previous = Array(previous).select { |v| v.is_a?(Hash) }
    inventory = field.subject_heading_inventory
    values.map do |value|
      snapshot = value.is_a?(String) ? JSON.parse(value) : value
      raise InvalidSelection, 'Invalid subject heading selection.' unless snapshot.is_a?(Hash) && snapshot.keys.sort == %w[heading uri]
      saved = previous.find { |v| v == snapshot }
      option = inventory&.subject_headings&.find_by(normalized_key: SubjectHeadings::Import.key(snapshot['heading'].to_s, snapshot['uri']))
      # Compare in Ruby too: database collations may ignore punctuation or case.
      raise InvalidSelection, 'Choose subject headings from the configured inventory.' unless saved || option&.snapshot == snapshot

      saved || option.snapshot
    end.uniq
  rescue JSON::ParserError, TypeError
    raise InvalidSelection, 'Invalid subject heading selection.'
  end
end
