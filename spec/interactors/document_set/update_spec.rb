require 'spec_helper'

describe DocumentSet::Update do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }
  let(:document_set_params) { {} }

  let(:result) do
    described_class.new(document_set: document_set, document_set_params: document_set_params, user: owner).call
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

  context 'when active slug conflict' do
    let(:document_set_params) do
      {
        title: 'New title',
        description: 'New description',
        slug: collection.slug,
        visibility: 'public'
      }
    end

    it 'uniquifies slug' do
      expect(result.success?).to be_truthy
      expect(result.document_set).to have_attributes(
        title: 'New title',
        description: 'New description',
        visibility: 'public',
        slug: "#{collection.slug}-set"
      )
    end
  end

  context 'when old conflict' do
    let(:time_stub) { Time.current.to_i }
    let(:slug) { "docset-conflict-slug-#{time_stub}" }
    let!(:other_document_set) do
      create(:document_set, collection_id: collection.id, owner_user_id: owner.id, slug: slug)
    end

    let!(:old_friendly_id) do
      FriendlyId::Slug.find_by(
        slug: other_document_set.slug,
        sluggable_type: 'DocumentSet',
        sluggable_id: other_document_set.id
      )
    end

    let(:document_set_params) do
      {
        slug: slug
      }
    end

    it 'reclaims old slug' do
      other_document_set.update!(slug: "changed-docset-slug-#{time_stub}")

      expect(result.success?).to be_truthy
      expect(result.document_set.slug).to eq(slug)
      expect(old_friendly_id.reload.slug).to include("#{slug}-reclaimed-")
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
