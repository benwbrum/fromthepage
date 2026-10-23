require 'spec_helper'

RSpec.describe CollectionHelper, type: :helper do
  describe 'notes_visible?' do
    let(:owner) { build_stubbed(:user) }
    let(:collection) { build_stubbed(:collection, owner_user_id: owner.id, hide_notes: false) }

    context 'when hide_notes is false (default)' do
      it 'returns true for nil user' do
        expect(notes_visible?(collection, nil)).to be true
      end

      it 'returns true for any user' do
        user = build_stubbed(:user)
        expect(notes_visible?(collection, user)).to be true
      end
    end

    context 'when hide_notes is true' do
      let(:collection) { build_stubbed(:collection, owner_user_id: owner.id, hide_notes: true) }

      it 'returns false for nil user' do
        expect(notes_visible?(collection, nil)).to be false
      end

      it 'returns false for a regular user who is not an owner or collaborator' do
        user = build_stubbed(:user)
        allow(user).to receive(:like_owner?).with(collection).and_return(false)
        allow(user).to receive(:collaborator?).with(collection).and_return(false)

        expect(notes_visible?(collection, user)).to be false
      end

      it 'returns true for a user who is an owner' do
        user = build_stubbed(:user)
        allow(user).to receive(:like_owner?).with(collection).and_return(true)
        allow(user).to receive(:collaborator?).with(collection).and_return(false)

        expect(notes_visible?(collection, user)).to be true
      end

      it 'returns true for a user who is a collaborator' do
        user = build_stubbed(:user)
        allow(user).to receive(:like_owner?).with(collection).and_return(false)
        allow(user).to receive(:collaborator?).with(collection).and_return(true)

        expect(notes_visible?(collection, user)).to be true
      end
    end

    context 'when called with a document_set whose parent collection hides notes' do
      let(:collection) { build_stubbed(:collection, owner_user_id: owner.id, hide_notes: true) }
      let(:document_set) { build_stubbed(:document_set, collection: collection) }

      it 'returns false for nil user' do
        expect(notes_visible?(document_set, nil)).to be false
      end

      it 'returns true for a user who is an owner' do
        user = build_stubbed(:user)
        allow(user).to receive(:like_owner?).with(document_set).and_return(true)
        allow(user).to receive(:collaborator?).with(document_set).and_return(false)

        expect(notes_visible?(document_set, user)).to be true
      end
    end
  end

  describe 'any_public_collections_with_document_sets?' do
    it 'returns true if any of the collections in this group of objects is not restricted AND supports doc sets' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, visibility: :public, supports_document_sets: true)
      group = [collection]

      expect(any_public_collections_with_document_sets?(group)).to be true
    end

    it 'returns false if none of the collections in this group of objects are !restricted AND supports doc sets' do
      user = build_stubbed(:user)
      collection1 = build_stubbed(:collection, owner_user_id: user.id, visibility: :private, supports_document_sets: true)
      collection2 = build_stubbed(:collection, owner_user_id: user.id, visibility: :public, supports_document_sets: false)
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
