require 'spec_helper'

describe AiTranscription::Create do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, :with_image, work: work) }

  let(:user) { owner }
  let(:model) { nil }
  let(:prompt_file) { nil }
  let(:retranscribe) { false }

  let(:prompt) { File.read(Rails.root.join('lib/transcription_prompt.txt')) }

  let(:result) do
    described_class.new(
      page: page,
      user: user,
      model: model,
      prompt_file: prompt_file,
      retranscribe: retranscribe
    ).call
  end

  before do
    Current.user = user
  end

  it 'initializes processing ai_transcription record' do
    expect(result.success?).to be_truthy
    expect(result.ai_transcription).to have_attributes(
      page_id: page.id,
      model: AiTranscription::DEFAULT_MODEL,
      prompt: prompt,
      status: 'processing'
    )
  end

  context 'when user is admin' do
    let!(:user) { create(:unique_user, :admin) }

    it 'initializes processing ai_transcription record' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription).to have_attributes(
        page_id: page.id,
        model: AiTranscription::DEFAULT_MODEL,
        prompt: prompt,
        status: 'processing'
      )
    end
  end

  context 'when custom model' do
    let(:model) { 'gemini-1.5.pro' }

    it 'initializes processing ai_transcription record' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription).to have_attributes(
        page_id: page.id,
        model: model,
        prompt: prompt,
        status: 'processing'
      )
    end
  end

  context 'when custom prompt exists' do
    let(:prompt_file) { 'test_data/ai_transcriptions/custom_prompt.txt' }
    let(:prompt) { File.read(Rails.root.join(prompt_file)) }

    it 'initializes processing ai_transcription record' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription).to have_attributes(
        page_id: page.id,
        model: AiTranscription::DEFAULT_MODEL,
        prompt: prompt,
        status: 'processing'
      )
      expect(prompt).to eq("This is a custom prompt\n")
    end
  end

  context 'when custom prompt does not exist' do
    let(:prompt_file) { 'test_data/ai_transcription/missing_prompt.txt' }
    let(:prompt) do
      'Please transcribe all the text you see in this image. ' \
      'Preserve the original formatting, line breaks, and layout as much as possible. ' \
      'If the text is handwritten, do your best to interpret it accurately. ' \
      'Do not add any commentary or explanations - only provide the transcribed text.'
    end

    it 'initializes processing ai_transcription record' do
      expect(result.success?).to be_truthy
      expect(result.ai_transcription).to have_attributes(
        page_id: page.id,
        model: AiTranscription::DEFAULT_MODEL,
        prompt: prompt,
        status: 'processing'
      )
    end
  end

  context 'when ai_transcription for page exist' do
    context 'when status is new' do
      let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, source_text: nil, status: :new) }

      it 'updates processing ai_transcription record' do
        expect(result.success?).to be_truthy
        expect(result.ai_transcription).to have_attributes(
          id: ai_transcription.id,
          page_id: page.id,
          model: AiTranscription::DEFAULT_MODEL,
          prompt: prompt,
          status: 'processing'
        )
      end
    end

    context 'when status is error' do
      let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, source_text: nil, status: :error) }

      it 'updates processing ai_transcription record' do
        expect(result.success?).to be_truthy
        expect(result.ai_transcription).to have_attributes(
          id: ai_transcription.id,
          page_id: page.id,
          model: AiTranscription::DEFAULT_MODEL,
          prompt: prompt,
          status: 'processing'
        )
      end
    end

    context 'when status is processing' do
      let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, source_text: nil, status: :processing) }

      it 'blocks user from creating ai_transcription' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to eq('AI Transcription generation is either in progress or completed!')
      end

      context 'when retranscribe is true' do
        let(:retranscribe) { true }

        it 'creates new processing ai_transcription record' do
          expect(result.success?).to be_truthy
          expect(result.ai_transcription).to have_attributes(
            page_id: page.id,
            model: AiTranscription::DEFAULT_MODEL,
            prompt: prompt,
            status: 'processing'
          )
          expect(result.ai_transcription.id).not_to eq(ai_transcription.id)
        end
      end
    end

    context 'when status is finished' do
      let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, source_text: nil, status: :finished) }

      it 'blocks user from creating ai_transcription' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to eq('AI Transcription generation is either in progress or completed!')
      end

      context 'when retranscribe is true' do
        let(:retranscribe) { true }

        it 'creates new processing ai_transcription record' do
          expect(result.success?).to be_truthy
          expect(result.ai_transcription).to have_attributes(
            page_id: page.id,
            model: AiTranscription::DEFAULT_MODEL,
            prompt: prompt,
            status: 'processing'
          )
          expect(result.ai_transcription.id).not_to eq(ai_transcription.id)
        end
      end
    end
  end

  context 'when user has no permission' do
    let!(:user) { create(:unique_user) }
    let!(:collection) { create(:collection, owner_user_id: owner.id, restricted: true, blocked_users: [user]) }

    it 'blocks user from creating ai_transcription' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('User has no permission to create AiTranscription on this page')
    end
  end
end
