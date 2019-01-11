require 'spec_helper'

RSpec.describe CollectionHelper, type: :helper do
  describe 'any_public_collections_with_document_sets?' do
    it 'returns true if any of the collections in this group of objects is not restricted AND supports doc sets' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: false, supports_document_sets: true)
      group = [collection]

      expect(any_public_collections_with_document_sets?(group)).to be true
    end

    it 'returns false if none of the collections in this group of objects are !restricted AND supports doc sets' do
      user = build_stubbed(:user)
      collection1 = build_stubbed(:collection, owner_user_id: user.id, restricted: true, supports_document_sets: true)
      collection2 = build_stubbed(:collection, owner_user_id: user.id, restricted: false, supports_document_sets: false)
      group = [collection1, collection2]

      expect(any_public_collections_with_document_sets?(group)).to be false
    end
  end

  describe 'is_a_public_collection?' do
    it 'returns true if the object is a Collection and is public' do
      user = build_stubbed(:user)
      collection_or_doc_set = build_stubbed(:collection, owner_user_id: user.id, supports_document_sets: true)
      allow(collection_or_doc_set).to receive(:is_public).and_return(true)

      expect(is_a_public_collection?(collection_or_doc_set)).to be true
    end

    it 'returns false if the object is not a Collection but is public' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, supports_document_sets: true)
      collection_or_doc_set = build_stubbed(:document_set, collection_id: collection.id)
      allow(collection_or_doc_set).to receive(:is_public).and_return(true)

      expect(is_a_public_collection?(collection_or_doc_set)).to be false
    end

    it 'returns false if the object is a Collection but is not public' do
      user = build_stubbed(:user)
      collection_or_doc_set = build_stubbed(:collection, owner_user_id: user.id, supports_document_sets: true)
      allow(collection_or_doc_set).to receive(:is_public).and_return(false)

      expect(is_a_public_collection?(collection_or_doc_set)).to be false
    end
  end

  describe 'is_a_private_document_set?' do
    it 'returns true if the object is a DocumentSet and is private' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, supports_document_sets: true)
      collection_or_doc_set = build_stubbed(:document_set, collection_id: collection.id)
      allow(collection_or_doc_set).to receive(:is_public).and_return(false)

      expect(is_a_private_document_set?(collection_or_doc_set)).to be true
    end

    it 'returns false if the object is not a DocumentSet but is private' do
      user = build_stubbed(:user)
      collection_or_doc_set = build_stubbed(:collection, owner_user_id: user.id)
      allow(collection_or_doc_set).to receive(:is_public).and_return(false)

      expect(is_a_private_document_set?(collection_or_doc_set)).to be false
    end

    it 'returns false if the object is a DocumentSet but is public' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, supports_document_sets: true)
      collection_or_doc_set = build_stubbed(:document_set, collection_id: collection.id)
      allow(collection_or_doc_set).to receive(:is_public).and_return(true)

      expect(is_a_private_document_set?(collection_or_doc_set)).to be false
    end
  end

end
