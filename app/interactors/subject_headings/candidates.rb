class SubjectHeadings::Candidates
  LIMIT = 40
  STOP_WORDS = %w[the and for that this with from were was are have has had not but his her she him they them their you your into upon said shall will would could should been being].freeze

  # Small lexical ranker. Heading tokens carry inverse document frequency;
  # uncommon words in the vocabulary outweigh generic ones. No LLM retrieval.
  def self.call(field:, text:)
    headings = field.subject_heading_inventory&.subject_headings&.order(:id)&.to_a || []
    terms = ->(value) { value.to_s.downcase.scan(/[\p{L}\p{N}]+/).reject { |w| w.size < 3 || STOP_WORDS.include?(w) }.uniq }
    context = terms.call(text).to_set
    documents = headings.map { |h| [h, terms.call(h.heading)] }
    frequency = Hash.new(0)
    documents.each { |_, tokens| tokens.each { |token| frequency[token] += 1 } }
    documents.filter_map do |heading, tokens|
      matches = tokens.select { |t| context.include?(t) }
      next if matches.empty?
      score = matches.sum { |t| Math.log(1.0 + headings.size.to_f / frequency[t]) } / Math.sqrt([tokens.size, 1].max)
      [score, heading]
    end.sort_by { |score, h| [-score, h.id] }.first(LIMIT).to_h do |_, h|
      ["sh_#{h.id}", h.snapshot]
    end
  end
end
