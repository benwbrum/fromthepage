require 'net/http'
require 'base64'

class AiTranscription::Lib::BaseTranscribeHandler
  MAX_RETRY = 5
  IMAGE_FETCH_LIMIT = 10
  MAX_IMAGE_DIM = 7900

  CLAUDE_SUPPORTED_FORMATS = %w[JPEG PNG GIF WEBP].freeze

  def initialize(prompt:, model:, image_url:, image_path: nil)
    @prompt = prompt
    @model = model
    @image_url = image_url
    @image_path = image_path
  end

  protected

  def read_and_encode_image(path)
    encode_image_bytes(File.binread(path))
  end

  def fetch_and_encode_image_for_claude(url:, limit: IMAGE_FETCH_LIMIT)
    raise ArgumentError, 'Too many HTTP redirects' if limit.zero?

    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    case response
    when Net::HTTPSuccess
      encode_image_bytes(response.body)
    when Net::HTTPRedirection
      location = response['location']
      Rails.logger.info("Following redirect to: #{location}")
      fetch_and_encode_image_for_claude(url: location, limit: limit - 1)
    else
      raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
    end
  end

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

  private

  def encode_image_bytes(bytes)
    image_list = Magick::ImageList.new
    image = nil
    resized_image = nil

    begin
      image_list.from_blob(bytes)
      image = image_list.first

      if image.columns > MAX_IMAGE_DIM || image.rows > MAX_IMAGE_DIM
        scale = [MAX_IMAGE_DIM.to_f / image.columns, MAX_IMAGE_DIM.to_f / image.rows].min
        resized_image = image.thumbnail(scale)
        image = resized_image
      end

      image.format = 'JPEG' unless CLAUDE_SUPPORTED_FORMATS.include?(image.format.upcase)

      media_type = claude_media_type(image.format)
      [Base64.strict_encode64(image.to_blob), media_type]
    ensure
      resized_image&.destroy!
      image_list&.destroy!
    end
  end

  def claude_media_type(format)
    case format.upcase
    when 'JPEG' then 'image/jpeg'
    when 'PNG'  then 'image/png'
    when 'GIF'  then 'image/gif'
    when 'WEBP' then 'image/webp'
    else 'image/jpeg'
    end
  end
end
