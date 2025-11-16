require 'spec_helper'

describe Page::FetchAiText do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let(:page) { create(:page, :with_image, work: work) }

  let(:result) do
    described_class.new(page: page).call
  end

  before do
    # Mock the Gemini API call
    allow(Gemini::TextTranscriber).to receive(:transcribe_image)
      .and_return('This is transcribed text from the image.')
  end

  describe '#call' do
    context 'when page has an image' do
      before do
        allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
      end

      it 'successfully transcribes the image' do
        expect(result.success?).to be_truthy
        expect(result.message).to eq('Successfully transcribed text from image using Gemini AI')
      end

      it 'saves the transcribed text to ai_plaintext' do
        result
        expect(page.ai_plaintext).to eq('This is transcribed text from the image.')
      end

      it 'calls the Gemini API with the correct image URL' do
        expect(Gemini::TextTranscriber).to receive(:transcribe_image)
          .with('http://example.com/image.jpg')
          .and_return('Transcribed text')

        result
      end
    end

    context 'when page has no image' do
      before do
        allow(page).to receive(:image_url_for_download).and_return(nil)
      end

      it 'fails with appropriate message' do
        expect(result.success?).to be_falsey
        expect(result.message).to eq('Page has no image to transcribe')
      end
    end

    context 'when Gemini API raises an error' do
      before do
        allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
        allow(Gemini::TextTranscriber).to receive(:transcribe_image)
          .and_raise(StandardError.new('API error'))
      end

      it 'fails with error message' do
        expect(result.success?).to be_falsey
        expect(result.message).to include('Failed to transcribe image')
        expect(result.message).to include('API error')
      end
    end

    context 'when GEMINI_API_KEY is not set' do
      before do
        allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
        allow(ENV).to receive(:[]).with('GEMINI_API_KEY').and_return(nil)
        allow(Gemini::TextTranscriber).to receive(:transcribe_image)
          .and_raise(ArgumentError.new('GEMINI_API_KEY environment variable is not set'))
      end

      it 'fails with appropriate message' do
        expect(result.success?).to be_falsey
        expect(result.message).to include('GEMINI_API_KEY environment variable is not set')
      end
    end
  end
end
