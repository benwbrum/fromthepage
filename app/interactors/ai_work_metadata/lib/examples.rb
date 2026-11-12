# Reviewed sample works used as few-shot examples when drafting the rest of a collection.
# Each example is the work's title, an excerpt of its transcript and the metadata the owner saved.
class AiWorkMetadata::Lib::Examples
  include Enumerable

  TEXT_LIMIT = 3_000

  Example = Struct.new(:title, :text, :values, keyword_init: true) do
    # Saved values keyed by field id, for fields the regular metadata prompt asks about
    def metadata_json(fields)
      fields.each_with_object({}) do |field, hash|
        value = values[field.id]
        hash[field.id.to_s] = value.presence
      end
    end

    # Headings the owner saved for a subject heading field
    def headings(field)
      Array(values[field.id]).compact_blank
    end
  end

  def initialize(collection:, work_ids:)
    @collection = collection
    @work_ids = Array(work_ids)
  end

  def each(&)
    examples.each(&)
  end

  def size
    examples.size
  end

  def empty?
    examples.empty?
  end

  private

  def examples
    @examples ||= begin
      works = @collection.works.where(id: @work_ids).includes(:pages).reorder(:id).to_a
      Page.preload_plaintext_for_ai(works.flat_map(&:pages))
      works.filter_map do |work|
        values = saved_values(work)
        next if values.empty?

        Example.new(title: work.title, text: work.plaintext_for_ai.truncate(TEXT_LIMIT, separator: ' '), values: values)
      end
    end
  end

  def saved_values(work)
    return {} if work.metadata_description.blank?

    JSON.parse(work.metadata_description).each_with_object({}) do |element, hash|
      hash[element['transcription_field_id'].to_i] = element['value']
    end
  rescue JSON::ParserError
    {}
  end
end
