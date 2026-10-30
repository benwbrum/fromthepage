module AiWorkMetadata::Lib::Common
  def sanitize_model
    @model ||= AiWorkMetadata::DEFAULT_MODEL
  end

  def build_prompt
    builder = AiWorkMetadata::Lib::PromptBuilder.new(work: @work)
    prompt = builder.build
    @subject_heading_candidates = builder.subject_heading_candidates
    prompt
  end

  def check_user_permission
    return if @user.admin?

    return if @user.like_owner?(@collection)

    raise ArgumentError, 'User has no permission to create AiWorkMetadata on this work'
  end
end
