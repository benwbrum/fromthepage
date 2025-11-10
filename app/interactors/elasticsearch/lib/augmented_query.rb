class Elasticsearch::Lib::AugmentedQuery
  def initialize(query:)
    @query = query
  end

  def perform
    return @query if @query.nil? || @query.include?('"')

    tokens = @query.split

    augmented_tokens = tokens.map do |t|
      if t.nil? || t.include?('"') || !t.match?(/[.\-_]/)
        t
      else
        '"' + t + '"'
      end
    end

    augmented_tokens.join(' ')
  end
end
