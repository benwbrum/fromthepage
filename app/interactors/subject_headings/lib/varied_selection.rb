# Picks `count` texts that together represent the variety of a set of documents, using only their words:
# TF-IDF vectors, spherical k-means with `count` clusters, then the most typical text (closest to the
# cluster centre) from each cluster. Typical documents make better examples for a cataloger than outliers.
class SubjectHeadings::Lib::VariedSelection
  ITERATIONS = 15
  MIN_WORD_LENGTH = 3
  MIN_DOCUMENT_FREQUENCY = 2
  MAX_CENTROID_TERMS = 2_000

  def initialize(texts, count:, seed: 0)
    @texts = texts
    @count = [count, texts.size].min
    @random = Random.new(seed)
  end

  # Indexes into `texts`, largest cluster first
  def indexes
    return [] if @count.zero?
    return (0...@texts.size).to_a if @count == @texts.size

    assignments = cluster
    clusters = assignments.each_with_index.group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    chosen = clusters.values
                     .sort_by { |members| -members.size }
                     .map { |members| members.max_by { |i| dot(vectors[i], @centroids[assignments[i]]) } }

    # A cluster can end up empty; fill any shortfall at random so callers always get `count` texts
    chosen + ((0...@texts.size).to_a - chosen).sample(@count - chosen.size, random: @random)
  end

  private

  def cluster
    @centroids = vectors.values_at(*(0...vectors.size).to_a.sample(@count, random: @random))
    assignments = nil

    ITERATIONS.times do
      new_assignments = vectors.map { |v| nearest_centroid(v) }
      break if new_assignments == assignments

      assignments = new_assignments
      @centroids = (0...@count).map { |c| centroid(vectors.each_index.select { |i| assignments[i] == c }) || @centroids[c] }
    end

    assignments
  end

  def nearest_centroid(vector)
    (0...@count).max_by { |c| dot(vector, @centroids[c]) }
  end

  def centroid(member_indexes)
    return nil if member_indexes.empty?

    sum = Hash.new(0.0)
    member_indexes.each { |i| vectors[i].each { |term, weight| sum[term] += weight } }
    normalize(sum.max_by(MAX_CENTROID_TERMS) { |_, weight| weight }.to_h)
  end

  def vectors
    @vectors ||= begin
      tokens = @texts.map { |text| text.to_s.downcase.scan(/[[:alpha:]]{#{MIN_WORD_LENGTH},}/) }
      document_frequency = Hash.new(0)
      tokens.each { |words| words.uniq.each { |w| document_frequency[w] += 1 } }

      tokens.map do |words|
        weights = words.tally.filter_map do |word, count|
          next if document_frequency[word] < MIN_DOCUMENT_FREQUENCY

          [word, (1 + Math.log(count)) * Math.log(@texts.size.to_f / document_frequency[word])]
        end
        normalize(weights.to_h)
      end
    end
  end

  def normalize(vector)
    norm = Math.sqrt(vector.values.sum { |w| w * w })
    norm.zero? ? vector : vector.transform_values { |w| w / norm }
  end

  def dot(a, b)
    a, b = b, a if a.size > b.size
    a.sum { |term, weight| weight * b.fetch(term, 0.0) }
  end
end
