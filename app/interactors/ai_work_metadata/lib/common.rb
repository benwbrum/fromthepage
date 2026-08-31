module AiWorkMetadata::Lib::Common
  def sanitize_model
    @model ||= AiWorkMetadata::DEFAULT_MODEL
  end

  def build_prompt
    AiWorkMetadata::Lib::PromptBuilder
      .new(work: @work)
      .build
  end

  def check_user_permission
    return if @user.admin?

    return if @user.like_owner?(@collection)

    raise ArgumentError, 'User has no permission to create AiWorkMetadata on this work'
  end
end
