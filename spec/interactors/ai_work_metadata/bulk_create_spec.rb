require 'spec_helper'

describe AiWorkMetadata::BulkCreate do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work_1) { create(:work, collection: collection) }
  let!(:work_2) { create(:work, collection: collection) }
  let!(:text_field) do
    create(:transcription_field, :as_metadata, :text_field,
           label: 'Title', collection: collection, position: 1, line_number: 1)
  end

  let(:user) { owner }
  let(:scope) { nil }

  let(:result) do
    described_class.new(collection: collection, user: user, scope: scope).call
  end

  before do
    Current.user = user
  end

  it 'initializes processing ai_work_metadata records for every work' do
    expect(result.success?).to be_truthy
    records = collection.works.includes(:ai_work_metadata).flat_map(&:ai_work_metadata)
    expect(records.size).to eq(2)
    expect(records.map(&:status).uniq).to eq(['processing'])
    expect(records.map(&:prompt)).to all(include(text_field.id.to_s))
  end

  context 'when the collection has no metadata fields' do
    let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
    let!(:work_1) { create(:work, collection: collection) }
    let!(:work_2) { create(:work, collection: collection) }
    let!(:text_field) { nil }

    it 'fails with an argument error' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('Collection has no metadata fields configured')
    end
  end

  context 'when scoped to a single work' do
    let(:scope) { { work_ids: [work_1.id] } }

    it 'only initializes records for the scoped work' do
      expect(result.success?).to be_truthy
      records = collection.works.includes(:ai_work_metadata).flat_map(&:ai_work_metadata)
      expect(records.size).to eq(1)
      expect(records.first.work_id).to eq(work_1.id)
    end
  end

  context 'when an ai_work_metadata already exists for a work' do
    context 'when status is new' do
      let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work_1.id, status: :new) }

      it 'updates the existing record instead of creating a new one' do
        expect(result.success?).to be_truthy
        records = collection.works.includes(:ai_work_metadata).flat_map(&:ai_work_metadata)
        expect(records.size).to eq(2)
        expect(records.map(&:id)).to include(ai_work_metadata.id)
        expect(ai_work_metadata.reload.status).to eq('processing')
      end
    end

    context 'when status is processing' do
      let!(:ai_work_metadata) { create(:ai_work_metadata, work_id: work_1.id, status: :processing) }

      it 'leaves the in-progress record untouched and does not create a duplicate' do
        expect(result.success?).to be_truthy
        records = collection.works.includes(:ai_work_metadata).flat_map(&:ai_work_metadata)
        expect(records.size).to eq(2)
      end
    end
  end

  context 'when user has no permission' do
    let!(:user) { create(:unique_user) }
    let!(:collection) { create(:collection, owner_user_id: owner.id, visibility: :private, blocked_users: [user], works: []) }

    it 'blocks the user' do
      expect(result.success?).to be_falsey
      expect(result.full_errors.message).to eq('User has no permission to create AiWorkMetadata on this work')
    end
  end
end
