require 'openai'

if ENABLE_OPENAI
  OpenAI.configure do |config|
    config.access_token = OPENAI_ACCESS_TOKEN
  end
end