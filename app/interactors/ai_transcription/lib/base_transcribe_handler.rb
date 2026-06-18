require 'net/http'
require 'base64'

class AiTranscription::Lib::BaseTranscribeHandler
  MAX_RETRY = 5
  IMAGE_FETCH_LIMIT = 10

  def initialize(prompt:, model:, image_url:)
    @prompt = prompt
    @model = model
    @image_url = image_url
  end

  protected

  def fetch_and_encode_image(url:, limit: IMAGE_FETCH_LIMIT)
    raise ArgumentError, 'Too many HTTP redirects' if limit.zero?

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      Base64.strict_encode64(response.body)
    when Net::HTTPRedirection
      location = response['location']
      Rails.logger.info("Following redirect to: #{location}")
      fetch_and_encode_image(url: location, limit: limit - 1)
    else
      raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
    end
  end
end
