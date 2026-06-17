# frozen_string_literal: true

require 'spec_helper'
require 'textract/page_processor'

# Minimal stand-ins for the AWS SDK response structs
class FakeTextractBlock
  def initialize(hash)
    @hash = hash
  end

  def to_h
    @hash
  end
end

class FakeTextractResponse
  attr_reader :blocks

  def initialize(blocks)
    @blocks = blocks.map { |b| FakeTextractBlock.new(b) }
  end
end

describe Textract::PageProcessor do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let(:page) { create(:page, work: work, base_width: 1000, base_height: 2000) }
  let(:textract_client) { instance_double('Aws::Textract::Client') }
  let(:processor) { described_class.new(page) }

  let(:textract_blocks) do
    [
      {
        id: 'line-1',
        block_type: 'LINE',
        text: 'Hello world',
        geometry: { bounding_box: { left: 0.1, top: 0.2, width: 0.5, height: 0.05 } },
        relationships: [{ type: 'CHILD', ids: %w[word-1 word-2] }]
      },
      {
        id: 'word-1',
        block_type: 'WORD',
        text: 'Hello',
        confidence: 98.5,
        geometry: { bounding_box: { left: 0.1, top: 0.2, width: 0.18, height: 0.05 } }
      },
      {
        id: 'word-2',
        block_type: 'WORD',
        text: 'world',
        confidence: 97.0,
        geometry: { bounding_box: { left: 0.3, top: 0.2, width: 0.2, height: 0.05 } }
      }
    ]
  end

  before do
    allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
    allow(processor).to receive(:fetch_image_bytes).and_return('fake-image-bytes')
    allow(processor).to receive(:textract_client).and_return(textract_client)
    allow(textract_client).to receive(:detect_document_text)
      .with(document: { bytes: 'fake-image-bytes' })
      .and_return(FakeTextractResponse.new(textract_blocks))
  end

  describe '#process_page' do
    it 'creates an AiTranscription with ALTO XML in prompt' do
      expect { processor.process_page }.to change(AiTranscription, :count).by(1)

      transcription = AiTranscription.last
      expect(transcription.model).to eq(AiTranscription::TEXTRACT_ALTO_MODEL)
      expect(transcription.prompt).to include('<alto')
      expect(transcription.prompt).to include('TextLine')
      expect(transcription.prompt).to include('String')
    end

    it 'saves derived plaintext into source_text' do
      processor.process_page
      expect(AiTranscription.last.source_text).to eq('Hello world')
    end

    it 'creates an ExternalApiRequest with engine textract and status completed' do
      expect { processor.process_page }.to change(ExternalApiRequest, :count).by(1)

      request = ExternalApiRequest.last
      expect(request.engine).to eq(ExternalApiRequest::Engine::TEXTRACT)
      expect(request.status).to eq(ExternalApiRequest::Status::COMPLETED)
      expect(request.page).to eq(page)
      expect(request.collection).to eq(collection)
    end

    it 'sets the AiTranscription status to finished' do
      processor.process_page
      expect(AiTranscription.last.status).to eq('finished')
    end

    context 'when image dimensions are missing' do
      before do
        allow(page).to receive(:base_width).and_return(nil)
        allow(page).to receive(:base_height).and_return(nil)
        allow(page).to receive(:sc_canvas).and_return(nil)
      end

      it 'raises ArgumentError and marks request as failed' do
        expect { processor.process_page }.to raise_error(ArgumentError, /Missing image dimensions/)
        expect(ExternalApiRequest.last.status).to eq(ExternalApiRequest::Status::FAILED)
      end
    end

    context 'when image URL is missing' do
      before do
        allow(page).to receive(:image_url_for_download).and_return(nil)
      end

      it 'marks the request as failed and returns without raising' do
        expect { processor.process_page }.not_to change { AiTranscription.where(page_id: page.id).count }
        expect(ExternalApiRequest.last.status).to eq(ExternalApiRequest::Status::FAILED)
      end
    end

    context 'when Textract raises a service error' do
      before do
        allow(textract_client).to receive(:detect_document_text)
          .and_raise(Aws::Textract::Errors::ServiceError.new(nil, 'Throttled'))
      end

      it 'marks the request as failed and re-raises the error' do
        expect { processor.process_page }.to raise_error(Aws::Textract::Errors::ServiceError)
        expect(ExternalApiRequest.last.status).to eq(ExternalApiRequest::Status::FAILED)
      end
    end

    context 'when an existing ExternalApiRequest is provided' do
      let(:existing_request) do
        create(:external_api_request,
               user: owner,
               collection: collection,
               work: work,
               page: page,
               engine: ExternalApiRequest::Engine::TEXTRACT,
               status: ExternalApiRequest::Status::QUEUED)
      end
      let(:processor) { described_class.new(page, existing_request) }

      it 'uses the provided request rather than creating a new one' do
        expect { processor.process_page }.not_to change(ExternalApiRequest, :count)
        expect(existing_request.reload.status).to eq(ExternalApiRequest::Status::COMPLETED)
      end
    end
  end

  describe '#initialize' do
    it 'creates a new ExternalApiRequest when none is provided' do
      p = described_class.new(page)
      request = p.instance_variable_get(:@external_api_request)

      expect(request).to be_a_new(ExternalApiRequest)
      expect(request.engine).to eq(ExternalApiRequest::Engine::TEXTRACT)
      expect(request.status).to eq(ExternalApiRequest::Status::QUEUED)
    end
  end
end
