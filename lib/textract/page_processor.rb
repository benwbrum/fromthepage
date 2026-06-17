# frozen_string_literal: true

require 'textract/alto_builder'

module Textract
  # Sends a single page image to Amazon Textract (synchronous API),
  # converts the response to ALTO-XML, and saves it as an AiTranscription
  # record. Also derives plaintext from the ALTO-XML and saves it as
  # source_text so it is immediately usable for AI Drafts.
  #
  # Usage:
  #   processor = Textract::PageProcessor.new(page)
  #   processor.process_page
  #
  # Environment variables required:
  #   AWS_ACCESS_KEY_ID
  #   AWS_SECRET_ACCESS_KEY
  #   AWS_REGION (defaults to 'us-east-1')
  class PageProcessor
    IMAGE_FETCH_LIMIT = 10

    def initialize(page, external_api_request = nil)
      @page = page

      if external_api_request.nil?
        @external_api_request = ExternalApiRequest.new
        @external_api_request.user = page.collection.owner
        @external_api_request.collection = page.collection
        @external_api_request.page = page
        @external_api_request.work = page.work
        @external_api_request.params = {}
        @external_api_request.engine = ExternalApiRequest::Engine::TEXTRACT
        @external_api_request.status = ExternalApiRequest::Status::QUEUED
      else
        @external_api_request = external_api_request
      end
    end

    # Synchronously processes the page: fetches the image, calls Textract,
    # converts the result to ALTO-XML, and persists it.
    def process_page
      @external_api_request.status = ExternalApiRequest::Status::RUNNING
      @external_api_request.save!

      image_url = @page.image_url_for_download
      unless image_url.present?
        Rails.logger.error("Textract::PageProcessor – no image URL for page #{@page.id}")
        @external_api_request.status = ExternalApiRequest::Status::FAILED
        @external_api_request.save!
        return
      end

      image_width = @page.base_width || @page.sc_canvas&.width
      image_height = @page.base_height || @page.sc_canvas&.height

      if image_width.blank? || image_height.blank?
        raise ArgumentError, "Missing image dimensions for page #{@page.id}. Textract ALTO conversion requires width and height."
      end

      image_bytes = fetch_image_bytes(image_url)

      response = textract_client.detect_document_text(
        document: { bytes: image_bytes }
      )

      blocks = response.blocks.map(&:to_h)

      alto_xml = Textract::AltoBuilder.new(
        blocks,
        image_width: image_width,
        image_height: image_height
      ).build

      plaintext = AltoTransformer.plaintext_from_alto_xml(alto_xml)

      AiTranscription.create!(
        page_id: @page.id,
        prompt: alto_xml,
        source_text: plaintext.presence || '',
        model: AiTranscription::TEXTRACT_ALTO_MODEL,
        status: :finished
      )

      @external_api_request.status = ExternalApiRequest::Status::COMPLETED
      @external_api_request.save!

      Rails.logger.info("Textract::PageProcessor – completed page #{@page.id}")
    rescue Aws::Textract::Errors::ServiceError => e
      Rails.logger.error("Textract API error for page #{@page.id}: #{e.message}")
      @external_api_request.status = ExternalApiRequest::Status::FAILED
      @external_api_request.save!
      raise
    rescue StandardError => e
      Rails.logger.error("Textract::PageProcessor error for page #{@page.id}: #{e.message}")
      @external_api_request.status = ExternalApiRequest::Status::FAILED
      @external_api_request.save!
      raise
    end

    private

    def textract_client
      @textract_client ||= Aws::Textract::Client.new(
        region: ENV.fetch('AWS_REGION', 'us-east-1'),
        access_key_id: ENV['AWS_ACCESS_KEY_ID'],
        secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
      )
    end

    def fetch_image_bytes(url, limit: IMAGE_FETCH_LIMIT)
      raise ArgumentError, 'Too many HTTP redirects' if limit.zero?

      uri = URI.parse(url)
      response = Net::HTTP.get_response(uri)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response['location']
        Rails.logger.info("Textract::PageProcessor – following redirect to #{location}")
        fetch_image_bytes(location, limit: limit - 1)
      else
        raise "Failed to fetch image from #{url}: #{response.code} #{response.message}"
      end
    end
  end
end
