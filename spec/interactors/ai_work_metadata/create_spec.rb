require 'spec_helper'

describe AiWorkMetadata::Create do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let(:user) { owner }
  let(:model) { nil }
  let(:retranscribe) { false }

  let(:result) do
    described_class.new(work: work, user: user, model: model, retranscribe: retranscribe).call
  end

  before do
    Current.user = user
  end

  it 'initializes a processing ai_work_metadata record' do
    expect(result.success?).to be_truthy
    expect(result.ai_work_metadata).to have_attributes(
      work_id: work.id,
      model: AiWorkMetadata::DEFAULT_MODEL,
      status: 'processing'
    )
  end

  it 'builds a prompt referencing the metadata fields' do
    expect(result.ai_work_metadata.prompt).to include(text_field.id.to_s)
  end

  context 'when a custom model is used' do
    let(:model) { 'claude-sonnet-4-6' }

    it 'uses the supplied model' do
      expect(result.success?).to be_truthy
      expect(result.ai_work_metadata.model).to eq(model)
    end
  end

  context 'when the collection has no metadata fields' do
    let!(:collection) { create(:collection, owner_user_id: owner.id) }
    let!(:work) { create(:work, collection: collection) }
    let!(:text_field) { nil }

    it 'fails with an argument error' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Collection has no metadata fields configured')
    end
  end

  context 'when an ai_work_metadata for the same engine already exists' do
    context 'when status is new' do
      let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work.id, status: :new) }

      it 'updates the existing record to processing' do
        expect(result.success?).to be_truthy
        expect(result.ai_work_metadata.id).to eq(ai_work_metadata.id)
        expect(result.ai_work_metadata.status).to eq('processing')
      end
    end

    context 'when status is processing' do
      let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work.id, status: :processing) }

      it 'blocks the user from creating a duplicate' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to eq('AI Work Metadata generation is either in progress or completed!')
      end

      context 'when retranscribe is true' do
        let(:retranscribe) { true }

        it 'creates a new processing record' do
          expect(result.success?).to be_truthy
          expect(result.ai_work_metadata.id).not_to eq(ai_work_metadata.id)
        end
      end
    end

    context 'when status is finished' do
      let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work.id, status: :finished) }

      it 'blocks the user from creating a duplicate' do
        expect(result.success?).to be_falsey
        expect(result.full_errors.message).to eq('AI Work Metadata generation is either in progress or completed!')
      end
    end
  end

  context 'when user has no permission' do
    let!(:user) { create(:unique_user) }
    let!(:collection) { create(:collection, owner_user_id: owner.id, visibility: :private, blocked_users: [user]) }

    it 'blocks the user' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('User has no permission to create AiWorkMetadata on this work')
    end
  end
end
