require 'spec_helper'

describe AiTranscription::BulkCreate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, pages: []) }
  let!(:page_1) { create(:page, :with_image, work: work) }
  let!(:page_2) { create(:page, :with_image, work: work) }

  let(:user) { owner }
  let(:scope) { nil }
  let(:prompt_file) { nil }

  let(:result) do
    described_class.new(
      collection: collection,
      user: user,
      scope: scope,
      prompt_file: prompt_file
    ).call
  end

  before do
    Current.user = user
  end

  it 'initializes processing ai_transcription records' do
    expect(result.success?).to be_truthy
    ai_transcriptions = collection.pages.includes(:ai_transcription).map(&:ai_transcription)
    expect(ai_transcriptions.size).to eq(2)
    expect(ai_transcriptions.pluck(:status).uniq).to eq(['processing'])
  end

  context 'when ai_transcription for page exist' do
    let!(:ai_transcription) { create(:ai_transcription, page_id: page_1.id, source_text: nil, status: :new) }

    it 'initializes processing ai_transcription records' do
      expect(result.success?).to be_truthy
      ai_transcriptions = collection.pages.includes(:ai_transcription).map(&:ai_transcription)
      expect(ai_transcriptions.size).to eq(2)
      expect(ai_transcriptions.pluck(:id)).to include(ai_transcription.id)
      expect(ai_transcriptions.pluck(:status).uniq).to eq(['processing'])
    end
  end

  context 'when scoped to a work' do
    let!(:work_2) { create(:work, collection: collection, pages: []) }
    let!(:page_3) { create(:page, :with_image, work: work_2) }

    let(:scope) { { work_ids: [work.id] } }

    it 'initializes processing ai_transcription records only for work 1' do
      expect(result.success?).to be_truthy
      ai_transcriptions = collection.pages.includes(:ai_transcription).map(&:ai_transcription).compact
      expect(ai_transcriptions.size).to eq(2)
      expect(ai_transcriptions.pluck(:status).uniq).to eq(['processing'])
    end
  end

  context 'when collection is field_based' do
    let!(:collection) { create(:collection, :field_based, owner_user_id: owner.id, works: []) }
    let!(:text_field) do
      create(:transcription_field, :text_field,
             label: 'Name', collection: collection, position: 1, line_number: 1)
    end
    let!(:select_field) do
      create(:transcription_field, :select_field,
             label: 'County', options: 'Beaver;Box Elder',
             collection: collection, position: 2, line_number: 2)
    end

    it 'builds a field-based prompt for every transcription' do
      expect(result.success?).to be_truthy

      prompts = collection.pages.includes(:ai_transcription).map { |page| page.ai_transcription.prompt }
      expect(prompts.uniq.one?).to be_truthy
      expect(prompts.first).to include(text_field.id.to_s, 'Name', select_field.id.to_s, 'County')
      expect(prompts.first).not_to include('Preserve the original formatting')
    end

    context 'when a custom prompt_file is supplied' do
      let(:prompt_file) { 'test_data/ai_transcriptions/custom_prompt.txt' }

      it 'uses the custom prompt instead of the field-based prompt' do
        expect(result.success?).to be_truthy

        prompts = collection.pages.includes(:ai_transcription).map { |page| page.ai_transcription.prompt }
        expect(prompts).to all(eq("This is a custom prompt\n"))
        expect(prompts.none? { |prompt| prompt.include?(text_field.id.to_s) }).to be_truthy
      end
    end
  end
end
