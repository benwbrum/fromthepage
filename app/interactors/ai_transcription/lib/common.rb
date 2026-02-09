module AiTranscription::Lib::Common
  # TODO: When we start supporting custom models from user,
  # sanitation should happen here to filter out supported models
  def sanitize_model
    @model ||= AiTranscription::DEFAULT_MODEL
  end

  def sanitize_prompt
    @prompt_file ||= 'lib/gemini/transcription_prompt.txt'

    File.read(File.join(Rails.root.join(@prompt_file)))
  rescue Errno::ENOENT
    # Fallback prompt if file doesn't exist
    'Please transcribe all the text you see in this image. ' \
    'Preserve the original formatting, line breaks, and layout as much as possible. ' \
    'If the text is handwritten, do your best to interpret it accurately. ' \
    'Do not add any commentary or explanations - only provide the transcribed text.'
  end

  def check_user_permission
    return if @user.admin?

    return if @user.like_owner?(@collection)

    raise ArgumentError, 'User has no permission to create AiTranscription on this page'
  end
end
