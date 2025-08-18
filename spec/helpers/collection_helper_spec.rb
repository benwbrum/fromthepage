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

  describe 'showing_all_works?' do
    before do
      @collection = instance_double('Collection')
      helper.instance_variable_set(:@collection, @collection)
    end

    it 'returns true when params[:works] is "show"' do
      allow(helper).to receive(:params).and_return({ works: 'show' })
      expect(helper.showing_all_works?).to be true
    end

    it 'returns false when params[:works] is "hide"' do
      allow(helper).to receive(:params).and_return({ works: 'hide' })
      expect(helper.showing_all_works?).to be false
    end

    it 'returns false when params[:works] is "untranscribed"' do
      allow(helper).to receive(:params).and_return({ works: 'untranscribed' })
      expect(helper.showing_all_works?).to be false
    end

    it 'returns false when params[:works] is blank and collection hide_completed is true' do
      allow(helper).to receive(:params).and_return({})
      allow(@collection).to receive(:hide_completed).and_return(true)
      expect(helper.showing_all_works?).to be false
    end

    it 'returns true when params[:works] is blank and collection hide_completed is false' do
      allow(helper).to receive(:params).and_return({})
      allow(@collection).to receive(:hide_completed).and_return(false)
      expect(helper.showing_all_works?).to be true
    end

    it 'returns true when params[:works] is blank and collection is nil' do
      allow(helper).to receive(:params).and_return({})
      helper.instance_variable_set(:@collection, nil)
      expect(helper.showing_all_works?).to be true
    end
  end

  describe 'collection_works_pagination_info' do
    let(:works) { double('works') }

    before do
      @collection = instance_double('Collection')
      helper.instance_variable_set(:@collection, @collection)
    end

    it 'returns standard pagination info when showing all works' do
      allow(helper).to receive(:showing_all_works?).and_return(true)
      allow(helper).to receive(:page_entries_info).with(works).and_return('Displaying all 5 works')
      
      expect(helper.collection_works_pagination_info(works)).to eq('Displaying all 5 works')
    end

    it 'returns custom text for single incomplete work' do
      allow(helper).to receive(:showing_all_works?).and_return(false)
      allow(works).to receive(:total_entries).and_return(1)
      allow(helper).to receive(:t).with('collection_helper.pagination.displaying_one_incomplete_work').and_return('Displaying 1 incomplete work')
      
      expect(helper.collection_works_pagination_info(works)).to eq('Displaying 1 incomplete work')
    end

    it 'returns custom text for multiple incomplete works' do
      allow(helper).to receive(:showing_all_works?).and_return(false)
      allow(works).to receive(:total_entries).and_return(3)
      allow(helper).to receive(:t).with('collection_helper.pagination.displaying_incomplete_works', count: 3).and_return('Displaying 3 incomplete works')
      
      expect(helper.collection_works_pagination_info(works)).to eq('Displaying 3 incomplete works')
    end
  end

end
