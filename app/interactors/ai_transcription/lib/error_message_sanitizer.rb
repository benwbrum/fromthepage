class AiTranscription::Lib::ErrorMessageSanitizer
  CREDENTIAL_PARAMETER = /([?&](?:key|api_key|token|access_token)=)[^&#\s]+/i

  def self.sanitize(message)
    return if message.nil?

    message.to_s.gsub(CREDENTIAL_PARAMETER, '\\1[FILTERED]')
  end
end
