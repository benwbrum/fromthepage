require 'spec_helper'

describe AiTranscription::GenerateJob do
  include ActiveJob::TestHelper

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

  subject(:worker) { described_class.new }

  let(:perform_worker) do
    worker.perform(user_id: owner.id, ai_transcription_id: ai_transcription.id)
  end

  context 'success' do
    before do
      allow(AiTranscription).to receive(:find)
        .with(ai_transcription.id)
        .and_return(ai_transcription)

      allow(ai_transcription).to receive(:page).and_return(page)
      allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')
    end

    it 'performs generate job' do
      VCR.use_cassette('ai_transcriptions/generate', record: :none, allow_playback_repeats: false) do
        perform_enqueued_jobs do
          perform_worker
        end
      end

      # Refer to `test_data/ai_transcriptions/gemini_3_response.json`
      # It contains an actual response from gemini
      expect(ai_transcription.reload).to have_attributes(
        source_text: expected_response["candidates"].first["content"]["parts"].second["text"],
        reasoning: expected_response["candidates"].first["content"]["parts"].first["text"],
        status: 'finished'
      )
    end

    context 'with the retired model persisted' do
      let(:model) { 'gemini-3-pro-preview' }

      it 'invokes Gemini with the default model' do
        VCR.use_cassette('ai_transcriptions/generate', record: :none, allow_playback_repeats: false) do
          perform_worker
        end

        expect(ai_transcription.reload.model).to eq('gemini-3.1-pro-preview')
      end
    end

    context 'when user is admin' do
      let!(:admin) { create(:unique_user, :admin) }

      let(:perform_worker) do
        worker.perform(user_id: admin.id, ai_transcription_id: ai_transcription.id)
      end

      it 'performs generate job' do
        VCR.use_cassette('ai_transcriptions/generate', record: :none, allow_playback_repeats: false) do
          perform_enqueued_jobs do
            perform_worker
          end
        end

        # Refer to `test_data/ai_transcriptions/gemini_3_response.json`
        # It contains an actual response from gemini
        expect(ai_transcription.reload).to have_attributes(
          source_text: expected_response["candidates"].first["content"]["parts"].second["text"],
          reasoning: expected_response["candidates"].first["content"]["parts"].first["text"],
          status: 'finished'
        )
      end
    end
  end

  context 'failure' do
    context 'when generation fails' do
      let(:error) { StandardError.new('RECITATION') }
      let(:result) do
        instance_double(
          'Result',
          success?: false,
          ai_transcription: ai_transcription,
          full_errors: error
        )
      end
      let(:service) { instance_double(AiTranscription::Generate, call: result) }

      before do
        allow(AiTranscription::Generate).to receive(:new).with(ai_transcription: ai_transcription).and_return(service)
      end

      it 'stores the failure message' do
        expect {
          perform_enqueued_jobs do
            perform_worker
          end
        }.to raise_error

        expect(ai_transcription.reload.status).to eq('error')
        expect(ai_transcription.error_message).to eq('RECITATION')
      end

      context 'when the provider error includes a credential' do
        let(:error) do
          StandardError.new('the server responded with status 429 for URL https://provider.example/v1/models?alt=json&api_key=fake-secret&format=text')
        end

        it 'stores a useful error without the credential' do
          expect { perform_worker }.to raise_error(StandardError)

          message = ai_transcription.reload.metadata['error_message']
          expect(message).to include('status 429')
          expect(message).to include('provider.example/v1/models?alt=json&api_key=[FILTERED]&format=text')
          expect(message).not_to include('fake-secret')
        end
      end
    end

    context 'API returns blank source_text and reasoning' do
      before do
        allow(AiTranscription).to receive(:find)
          .with(ai_transcription.id)
          .and_return(ai_transcription)

        allow(ai_transcription).to receive(:page).and_return(page)
        allow(page).to receive(:image_url_for_ai).and_return('http://example.com/image.jpg')
      end

      it 'performs generate job' do
        VCR.use_cassette('ai_transcriptions/generate_blank', record: :none, allow_playback_repeats: false) do
          expect {
            perform_enqueued_jobs do
              perform_worker
            end
          }.to raise_error
        end

        expect(ai_transcription.reload).to have_attributes(
          source_text: '',
          reasoning: '',
          status: 'error'
        )
      end
    end

    context 'failed to download image' do
      before do
        allow(AiTranscription).to receive(:find)
          .with(ai_transcription.id)
          .and_return(ai_transcription)

        allow(ai_transcription).to receive(:page).and_return(page)
        allow(page).to receive(:image_url_for_ai).and_return(nil)
      end

      it 'performs generate job' do
        expect {
          perform_enqueued_jobs do
            perform_worker
          end
        }.to raise_error

        expect(ai_transcription.reload.status).to eq('error')
      end
    end
  end

  context 'no permission' do
    let!(:user) { create(:unique_user) }

    let(:perform_worker) do
      worker.perform(user_id: user.id, ai_transcription_id: ai_transcription.id)
    end

    it 'performs generate job' do
      expect {
        perform_enqueued_jobs do
          perform_worker
        end
      }.to raise_error

      expect(ai_transcription.reload.status).to eq('error')
      expect(ai_transcription.error_message).to eq('User has no permission to create AiTranscription on this page')
    end
  end
end
