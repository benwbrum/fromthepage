require 'spec_helper'

describe Work::Create do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  let(:work_params) do
    {
      title: "Work #{Time.current.to_i}",
      description: "New work",
      collection_id: collection.slug
    }
  end

  let(:result) do
    described_class.new(
      work_params: work_params,
      user: owner
    ).call
  end

  it 'creates work' do
    expect(result.success?).to be_truthy
    expect(result.work.persisted?).to be_truthy
  end

  context 'when collection_id is from docset' do
    let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }

    let(:work_params) do
      {
        title: "Work #{Time.current.to_i}",
        description: "New work",
        collection_id: document_set.slug
      }
    end

    it 'creates work' do
      expect(result.success?).to be_truthy
      expect(result.work.persisted?).to be_truthy
      expect(document_set.reload.works).to include(result.work)
    end
  end

  context 'when missing collection_id' do
    let(:work_params) do
      {
        title: "Work #{Time.current.to_i}",
        description: "New work"
      }
    end

    it 'fails to create' do
      expect(result.success?).to be_falsey
      expect(result.work.errors).to include(:collection)
    end
  end
end
