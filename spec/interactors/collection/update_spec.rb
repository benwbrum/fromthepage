require 'spec_helper'

describe Collection::Update do
  before do
    Current.user = owner
  end

  let(:owner) { create(:unique_user, :owner) }
  let!(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      title: 'Old title',
      slug: 'old-slug',
      subjects_disabled: true,
      data_entry_type: Collection::DataEntryType::TEXT_ONLY,
      messageboards_enabled: false,
      is_active: false,
      field_based: false,
      voice_recognition: true,
      language: 'eng'
    )
  end
  let(:collection_params) { {} }

  let(:result) do
    described_class.new(
      collection: collection,
      collection_params: collection_params,
      user: owner
    ).call
  end

  context 'with invalid params' do
    let(:collection_params) do
      {
        title: 'ab',
        intro_block: '<b> invalid',
        messageboards_enabled: false
      }
    end

    it 'fails to update' do
      expect(result.success?).to be_falsey
      expect(result.collection.errors).to include(:title)
      expect(result.collection.errors).to include(:intro_block)
    end
  end

  context 'with valid params' do
    let!(:tag) { create(:tag) }
    let(:collection_params) do
      {
        title: 'New title',
        slug: 'new-slug',
        subjects_enabled: true,
        data_entry_type: true,
        messageboards_enabled: true,
        is_active: true,
        field_based: true,
        tags: [tag.id]
      }
    end

    it 'updates collection' do
      expect(result.success?).to be_truthy
      expect(result.collection).to have_attributes(
        title: 'New title',
        subjects_enabled: true,
        data_entry_type: Collection::DataEntryType::TEXT_AND_METADATA,
        messageboards_enabled: true,
        is_active: true,
        field_based: true,
        voice_recognition: false,
        language: nil
      )
      expect(result.collection.tags.first).to have_attributes(id: tag.id)
      expect(result.collection.messageboard_group.present?).to be_truthy
      expect(
        Deed.find_by(
          collection_id: collection.id,
          user_id: owner.id,
          deed_type: DeedType::COLLECTION_ACTIVE
        ).present?
      ).to be_truthy
    end

    context 'when active slug conflict' do
      let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: owner.id) }
      let(:collection_params) do
        {
          slug: document_set.slug
        }
      end

      it 'uniquifies slug' do
        expect(result.success?).to be_truthy
        expect(result.collection).to have_attributes(
          slug: "#{document_set.slug}-collection"
        )
      end
    end

    context 'when old conflict' do
      let(:time_stub) { Time.current.to_i }
      let(:slug) { "collection-conflict-slug-#{time_stub}" }
      let!(:other_collection) do
        create(:collection, owner_user_id: owner.id, slug: slug)
      end

      let!(:old_friendly_id) do
        FriendlyId::Slug.find_by(
          slug: other_collection.slug,
          sluggable_type: 'Collection',
          sluggable_id: other_collection.id
        )
      end

      let(:collection_params) do
        {
          slug: slug
        }
      end

      it 'reclaims old slug' do
        other_collection.update!(slug: "changed-collection-slug-#{time_stub}")

        expect(result.success?).to be_truthy
        expect(result.collection.slug).to eq(slug)
        expect(old_friendly_id.reload.slug).to include("#{slug}-reclaimed-")
      end
    end
  end
end
