require 'spec_helper'

describe AiTranscription::Generate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work) }

  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, model: model, prompt: prompt, status: :processing, source_text: nil, reasoning: nil) }

  let(:model) { AiTranscription::DEFAULT_MODEL }
  let(:prompt) { File.read(Rails.root.join('lib/transcription_prompt.txt')) }

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
      allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')
    end

    it 'generates ai_transcription text and reasoning' do
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
        expect(result.ai_transcription.metadata["thoughts_token_count"]).to eq(usage["thoughtsTokenCount"])
        expect(result.ai_transcription.metadata["total_token_count"]).to eq(usage["totalTokenCount"])
      end
    end

    context 'when 503 error' do
      before do
        stub_const('AiTranscription::Lib::BaseTranscribeHandler::MAX_RETRY', 1)
      end

      it 'generates ai_transcription text and reasoning' do
        VCR.use_cassette('ai_transcriptions/generate_503', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_falsey
        expect(result.full_errors.message.include?('the server responded with status 503')).to be_truthy
      end
    end

    context 'when 429 error' do
      it 'generates ai_transcription text and reasoning' do
        VCR.use_cassette('ai_transcriptions/generate_429', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_falsey
        expect(result.full_errors.message.include?('the server responded with status 429')).to be_truthy
      end
    end

    context 'when source_text and reasoning are both blank' do
      it 'generates failed ai_transcription' do
        VCR.use_cassette('ai_transcriptions/generate_blank', record: :none, allow_playback_repeats: false) do
          result
        end

        expect(result.success?).to be_falsey
        expect(result.full_errors.message.include?('AI Transcription has blank text and reasoning')).to be_truthy

        expect(result.ai_transcription).to have_attributes(
          source_text: '',
          reasoning: ''
        )
      end
    end

    context 'when source_text and reasoning are blank with a provider finish message' do
      before do
        allow_any_instance_of(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:perform)
          .and_return(['', '', {}, {
                        'candidates' => [{
                          'finishReason' => 'RECITATION',
                          'finishMessage' => 'The generated content was filtered because it may contain material that resembles existing copyrighted works.'
                        }]
                      }])
      end

      it 'includes provider details in the failure message' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to include('AI Transcription has blank text and reasoning.')
        expect(result.full_errors.message).to include('RECITATION')
        expect(result.full_errors.message).to include('The generated content was filtered because it may contain material that resembles existing copyrighted works.')
      end

      it 'stores structured provider error details' do
        result

        details = ai_transcription.reload.provider_error_details
        expect(details['finish_reason']).to eq('RECITATION')
        expect(details['finish_message']).to eq('The generated content was filtered because it may contain material that resembles existing copyrighted works.')
        expect(details['raw_response']['candidates'].first['finishReason']).to eq('RECITATION')
      end
    end
  end

  context 'when collection is field_based' do
    let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id) }
    let!(:work)       { create(:work, collection: collection) }
    let!(:page)       { create(:page, :with_image, work: work) }
    let!(:text_field) do
      create(:transcription_field, :text_field,
             label: 'Name', collection: collection, position: 1, line_number: 1)
    end
    let!(:select_field) do
      create(:transcription_field, :select_field,
             label: 'County', options: 'Beaver;Box Elder',
             collection: collection, position: 2, line_number: 2)
    end

    let!(:ai_transcription) do
      create(:ai_transcription,
             page_id: page.id, model: model, prompt: prompt,
             status: :processing, source_text: nil, reasoning: nil)
    end

    let(:valid_json_text) do
      JSON.generate(text_field.id.to_s => 'John Smith', select_field.id.to_s => 'Beaver')
    end

    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')
      allow_any_instance_of(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:perform)
        .and_return([valid_json_text, '', { prompt_token_count: 100, total_token_count: 200 }, nil])
    end

    it 'stores parsed JSON in transcription_json and leaves source_text blank' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription.transcription_json).to eq(
        text_field.id.to_s   => 'John Smith',
        select_field.id.to_s => 'Beaver'
      )
      expect(result.ai_transcription.source_text).to be_nil
    end

    it 'stores reasoning and metadata' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription.metadata['prompt_token_count']).to eq(100)
    end

    context 'when the response is wrapped in markdown code fences' do
      let(:fenced_json) { "```json\n#{valid_json_text}\n```" }

      before do
        allow_any_instance_of(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:perform)
          .and_return([fenced_json, '', {}, nil])
      end

      it 'strips the fences and stores valid JSON' do
        expect(result.success?).to be_truthy
        expect(result.ai_transcription.transcription_json).to eq(
          text_field.id.to_s   => 'John Smith',
          select_field.id.to_s => 'Beaver'
        )
      end
    end

    context 'when the response is not valid JSON' do
      before do
        allow_any_instance_of(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:perform)
          .and_return(['not valid json', '', {}, nil])
      end

      it 'fails and saves the raw response in source_text' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to include('Field-based AI transcription JSON validation failed')
        expect(result.ai_transcription.source_text).to eq('not valid json')
        expect(result.ai_transcription.transcription_json).to be_nil
      end
    end

    context 'when a select field contains an invalid value' do
      before do
        bad_json = JSON.generate(
          text_field.id.to_s   => 'John',
          select_field.id.to_s => 'NotACounty'
        )
        allow_any_instance_of(AiTranscription::Lib::Gemini::TranscribeHandler).to receive(:perform)
          .and_return([bad_json, '', {}, nil])
      end

      it 'fails with a descriptive validation error' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to include('County')
        expect(result.full_errors.message).to include('NotACounty')
      end

      it 'saves the raw response in source_text for debugging' do
        expect(result.ai_transcription.source_text).to be_present
        expect(result.ai_transcription.transcription_json).to be_nil
      end
    end
  end

  context 'when page has no image' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_ai).and_return(nil)
      allow(page).to receive(:local_image_path).and_return(nil)
    end

    it 'fails to generate transcription' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Page has no image to transcribe')
    end
  end

  context 'when image fetch redirect errors' do
    before do
      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')

      stub_const('AiTranscription::Lib::BaseTranscribeHandler::IMAGE_FETCH_LIMIT', 1)
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
      allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')

      stub_const('AiTranscription::Lib::BaseTranscribeHandler::IMAGE_FETCH_LIMIT', 1)
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
