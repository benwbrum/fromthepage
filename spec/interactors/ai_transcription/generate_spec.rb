require 'spec_helper'

describe AiTranscription::Generate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work) }

  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, model: model, prompt: prompt, status: :processing, source_text: nil, reasoning: nil) }

  let(:model) { AiTranscription::DEFAULT_MODEL }
  let(:prompt) { File.read(Rails.root.join('lib/gemini/transcription_prompt.txt')) }

  let(:expected_response) do
    JSON.parse(
      File.read(Rails.root.join('test_data/ai_transcriptions/gemini_3_response.json'))
    )
  end

  let(:result) do
    described_class.new(ai_transcription: ai_transcription).call
  end

  before do
    Current.user = owner
  end

  context 'when page has an image' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')
    end

    it 'generates ai_transcriptiont text and reasoning' do
      VCR.use_cassette('ai_transcriptions/generate', record: :none, allow_playback_repeats: false) do
        result
      end

      expect(result.success?).to be_truthy

      # Refer to `test_data/ai_transcriptions/gemini_3_response.json`
      # It contains an actual response from gemini
      expect(result.ai_transcription.source_text).to eq(expected_response["candidates"].first["content"]["parts"].second["text"])
      expect(result.ai_transcription.reasoning).to eq(expected_response["candidates"].first["content"]["parts"].first["text"])

      usage = expected_response["usageMetadata"]
      expect(result.ai_transcription.metadata["prompt_token_count"]).to eq(usage["promptTokenCount"])
      expect(result.ai_transcription.metadata["candidates_token_count"]).to eq(usage["candidatesTokenCount"])
      expect(result.ai_transcription.metadata["total_token_count"]).to eq(usage["totalTokenCount"])
    end

    context 'when model used does not support reasoning' do
      let(:model) { 'gemini-2.5-pro' }
      let(:expected_response) do
        JSON.parse(
          File.read(Rails.root.join('test_data/ai_transcriptions/gemini_2_response.json'))
        )
      end

      it 'generates ai_transcription text only' do
        VCR.use_cassette('ai_transcriptions/generate', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_truthy

        # Refer to `test_data/ai_transcriptions/gemini_2_response.json`
        # It contains an actual response from gemini
        expect(result.ai_transcription.source_text).to eq(expected_response["candidates"].first["content"]["parts"].first["text"])
        expect(result.ai_transcription.reasoning).to eq("")

        usage = expected_response["usageMetadata"]
        expect(result.ai_transcription.metadata["prompt_token_count"]).to eq(usage["promptTokenCount"])
        expect(result.ai_transcription.metadata["candidates_token_count"]).to eq(usage["candidatesTokenCount"])
        expect(result.ai_transcription.metadata["total_token_count"]).to eq(usage["totalTokenCount"])
      end
    end

    context 'when 503 error' do
      before do
        stub_const('AiTranscription::Lib::Gemini::TranscribeHandler::MAX_RETRY', 1)
      end

      it 'generates ai_transcriptiont text and reasoning' do
        VCR.use_cassette('ai_transcriptions/generate_503', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_falsey
        expect(result.full_errors.message.include?('the server responded with status 503')).to be_truthy
      end
    end

    context 'when 429 error' do
      it 'generates ai_transcriptiont text and reasoning' do
        VCR.use_cassette('ai_transcriptions/generate_429', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_falsey
        expect(result.full_errors.message.include?('the server responded with status 429')).to be_truthy
      end
    end
  end

  context 'when page has no image' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_download).and_return(nil)
    end

    it 'fails to generate transcription' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Page has no image to transcribe')
    end
  end

  context 'when image fetch redirect errors' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')

      stub_const('AiTranscription::Lib::Gemini::TranscribeHandler::IMAGE_FETCH_LIMIT', 1)
    end

    it 'fails to generate transcription' do
      VCR.use_cassette('ai_transcriptions/generate_fetch_image_redirect_failure', record: :none, allow_playback_repeats: false) do
        result
      end

      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Too many HTTP redirects')
    end
  end

  context 'when image fetch unhandled errors' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_download).and_return('http://example.com/image.jpg')

      stub_const('AiTranscription::Lib::Gemini::TranscribeHandler::IMAGE_FETCH_LIMIT', 1)
    end

    it 'fails to generate transcription' do
      VCR.use_cassette('ai_transcriptions/generate_fetch_image_unhandled_failure', record: :none, allow_playback_repeats: false) do
        result
      end

      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Failed to fetch image from http://example.com/image.jpg: 500 Internal Server Error')
    end
  end
end
