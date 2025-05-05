require 'spec_helper'

describe DocumentSet::Update do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }
  let(:document_set_params) { {} }

  let(:result) do
    described_class.new(document_set: document_set, document_set_params: document_set_params).call
  end

  context 'when valid params' do
    let(:document_set_params) do
      {
        title: 'New title',
        description: 'New description',
        slug: 'newslug',
        visibility: 'public'
      }
    end

    it 'updates document_set' do
      expect(result.success?).to be_truthy
      expect(result.document_set).to have_attributes(
        title: 'New title',
        description: 'New description',
        visibility: 'public'
      )
    end
  end

  context 'when invalid params' do
    let(:document_set_params) do
      {
        title: ''
      }
    end

    it 'updates document_set' do
      expect(result.success?).to be_falsey
      expect(result.document_set.errors.full_messages).to include(
        "Title can't be blank",
        'Title is too short (minimum is 3 characters)'
      )
    end
  end
end
