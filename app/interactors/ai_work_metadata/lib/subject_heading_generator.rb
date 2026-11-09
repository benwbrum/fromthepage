# Asks the model for subject headings for one work and one subject heading field.
# Returns [candidates, reasoning, usage]: candidates are SubjectHeading snapshots ({'heading', 'uri'}).
class AiWorkMetadata::Lib::SubjectHeadingGenerator
  def initialize(work:, field:, model: AiWorkMetadata::SUBJECT_HEADING_MODEL)
    @work = work
    @field = field
    @model = model
  end

  def perform
    response_text, reasoning, usage, _response = handler.perform

    parser = AiWorkMetadata::Lib::SubjectHeadingResponseParser.new(response_text: response_text, prompt_builder: prompt_builder)
    candidates = parser.candidates
    raise ArgumentError, 'AI subject heading response could not be parsed' if parser.malformed? && candidates.empty?

    usage = usage.merge(model: @model, invalid_ids: parser.invalid_ids.presence, malformed_json: parser.malformed? || nil).compact
    [candidates, reasoning, usage]
  end

  private

  def prompt_builder
    @prompt_builder ||= AiWorkMetadata::Lib::SubjectHeadingPromptBuilder.new(work: @work, field: @field)
  end

  def handler
    AiWorkMetadata::Lib::Gemini::GenerateHandler.new(
      model: @model,
      system_instruction: prompt_builder.system_instruction,
      prompt: prompt_builder.user_prompt,
      json_response: true
    )
  end
end
