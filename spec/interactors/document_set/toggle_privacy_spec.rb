require 'spec_helper'

describe DocumentSet::TogglePrivacy do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }

  let(:result) do
    described_class.call(document_set: document_set)
  end

  it 'toggles document_set privacy' do
    expect(document_set.restricted).to be_truthy

    expect(result.success?).to be_truthy
    expect(document_set.restricted).to be_falsey
  end
end
