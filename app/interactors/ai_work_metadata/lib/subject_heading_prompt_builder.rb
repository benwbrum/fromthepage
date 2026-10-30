# Builds the prompt for assigning subject headings from a field's authority list (SubjectHeadingInventory).
#
# The system instruction (guidelines, collection description, local practice notes, and the full
# vocabulary) is identical for every work in the collection, so the provider can cache it; only the
# user prompt (title + transcript) changes per work. Each heading gets a short ID ("H0001") that the
# model returns and we map back to the heading, so headings can't be misspelled or invented.
class AiWorkMetadata::Lib::SubjectHeadingPromptBuilder
  def initialize(work:, field:)
    @work = work
    @field = field
    @collection = work.collection
  end

  def system_instruction
    <<~PROMPT
      You are a metadata librarian assigning subject headings from a controlled vocabulary to archival documents.

      Each request gives you one document from the collection described below: its title and a transcript of its text. Choose the subject headings that a cataloger would assign to it, using ONLY headings from the controlled vocabulary below.

      COLLECTION: #{@collection.title}
      #{collection_description}

      Guidelines:
      - Assign headings for the people and organizations who wrote, received, or are substantially discussed in the document, and for its main topics.
      - Prefer the most specific applicable heading. Do not assign a heading for a passing mention.
      - Most documents receive between 2 and 8 headings.
      - Every heading you assign must appear in the vocabulary exactly. Never invent or combine headings.
      - Do not assign headings for the document's own form or genre (for example a letter or a report) unless the document is about that subject.
      - Do not assign headings for what the whole collection is about (see the collection description) unless the document is specifically about that topic.
      #{local_practice}
      Respond with JSON only, in this form:
      {"headings": [{"id": "#{id_for(0)}", "heading": "exact heading text"}]}

      CONTROLLED VOCABULARY (id, heading):
      #{vocabulary}
    PROMPT
  end

  def user_prompt
    label = @work.machine_plaintext_for_ai? ? 'TRANSCRIPT (some or all of it is machine transcription and may contain errors)' : 'TRANSCRIPT'
    "TITLE: #{@work.title}\n\n#{label}:\n#{@work.plaintext_for_ai}"
  end

  # SubjectHeading for an ID the model returned, or nil
  def heading_for(id)
    index = id.to_s[/\AH(\d+)\z/, 1]&.to_i
    return nil if index.nil? || index < 1

    headings[index - 1]
  end

  def headings
    @headings ||= @field.subject_heading_inventory.subject_headings.order(:heading, :id).to_a
  end

  private

  def id_for(index)
    "H#{(index + 1).to_s.rjust(id_width, '0')}"
  end

  def id_width
    [4, headings.size.to_s.size].max
  end

  def vocabulary
    headings.each_with_index.map { |heading, i| "#{id_for(i)} #{heading.heading}" }.join("\n")
  end

  def collection_description
    CGI.unescapeHTML(Rails::Html::FullSanitizer.new.sanitize(@collection.intro_block.to_s)).squish
  end

  def local_practice
    return '' if @field.subject_heading_instructions.blank?

    "\nLocal cataloging practice for this collection (follow it where it differs from the guidelines above):\n" \
      "#{@field.subject_heading_instructions.strip}\n"
  end
end
