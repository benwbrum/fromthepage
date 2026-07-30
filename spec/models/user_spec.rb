require 'spec_helper'

describe User do
  describe 'website normalization and validation' do
    let(:user) { build(:unique_user, :owner) }

    it 'normalizes schemeless website URLs with https' do
      user.website = 'www.example.com'

      expect(user).to be_valid

      user.save!
      expect(user.reload.website).to eq('https://www.example.com')
    end

    it 'strips surrounding whitespace from website values' do
      user.website = '  https://example.com  '

      expect(user).to be_valid

      user.save!
      expect(user.reload.website).to eq('https://example.com')
    end

    it 'keeps valid urls with path, query, and fragment' do
      user.website = 'example.com/path?q=1#section'

      expect(user).to be_valid

      user.save!
      expect(user.reload.website).to eq('https://example.com/path?q=1#section')
    end

    it 'allows blank website values' do
      user.website = '  '

      expect(user).to be_valid

      user.save!
      expect(user.reload.website).to eq('')
    end
  end
  describe '#can_transcribe?' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, :private, :docset_enabled, owner_user_id: owner.id) }
    let(:work) { create(:work, collection: collection) }
    let(:collaborator) { create(:unique_user) }


    context 'when document set is private and work is restricted' do
      let(:document_set) { create(:document_set, :private, collection_id: collection.id, owner_user_id: owner.id) }
      before do
        document_set.works << work
      end

      before { work.update!(restrict_scribes: true) }

      it 'returns false for a document set collaborator' do
        document_set.collaborators << collaborator
        expect(collaborator.can_transcribe?(work, document_set)).to be false
      end

      it 'returns false for a parent collection collaborator' do
        collection.collaborators << collaborator
        expect(collaborator.can_transcribe?(work, document_set)).to be false
      end

      it 'returns true for an explicit work scribe' do
        work.scribes << collaborator
        expect(collaborator.can_transcribe?(work, document_set)).to be true
      end

      it 'returns true for the collection owner' do
        expect(owner.can_transcribe?(work, document_set)).to be true
      end
    end

    context 'when document set is private and work is not restricted' do
      let(:document_set) { create(:document_set, :private, collection_id: collection.id, owner_user_id: owner.id) }
      before do
        document_set.works << work
      end

      it 'returns true for a document set collaborator' do
        document_set.collaborators << collaborator
        expect(collaborator.can_transcribe?(work, document_set)).to be true
      end
    end

    context 'when document set is public and work is restricted' do
      let(:document_set) { create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id) }
      before do
        document_set.works << work
      end

      before do
        work.update!(restrict_scribes: true)
      end

      it 'returns false for a regular user' do
        expect(collaborator.can_transcribe?(work, document_set)).to be false
      end

      it 'returns true for an explicit work scribe' do
        work.scribes << collaborator
        expect(collaborator.can_transcribe?(work, document_set)).to be true
      end

      it 'returns true for the collection owner' do
        expect(owner.can_transcribe?(work, document_set)).to be true
      end
    end

    context 'when document set is public and work is not restricted' do
      let(:document_set) { create(:document_set, :public, collection_id: collection.id, owner_user_id: owner.id) }

      before { document_set.works << work }

      it 'returns true for any user' do
        expect(collaborator.can_transcribe?(work, document_set)).to be true
      end
    end
  end

  describe '#last_deed_at' do
    let(:user) { create(:unique_user) }

    it 'returns the created_at of the most recent deed' do
      allow_any_instance_of(Deed).to receive(:calculate_prerender)
      allow_any_instance_of(Deed).to receive(:calculate_prerender_mailer)
      older = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 2.days.ago)
      newest = create(:deed, user: user, deed_type: DeedType.all_types.first, created_at: 1.day.ago)
      expect(user.last_deed_at.to_i).to eq(newest.created_at.to_i)
      Deed.destroy(older.id)
      Deed.destroy(newest.id)
    end
  end

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:user_1) { create(:unique_user, :owner, real_name: identifier) }
    let!(:user_2) { create(:unique_user, :owner, about: identifier) }
    let!(:user_3) { create(:unique_user, :owner, website: "https://#{identifier}.com") }
    let!(:user_4) { create(:unique_user, :owner) }

    let(:records) do
      [
        user_1,
        user_2,
        user_3,
        user_4
      ]
    end

    before(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      UsersIndex.purge
      records.each(&:save!)
    end

    after(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      records.each(&:destroy!)
      UsersIndex.purge

      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
    end

    describe '#self.es_search' do
      let(:query) { identifier }
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: query) }

      it 'returns correct user ids' do
        expect(es_search.pluck("_id").map(&:to_i)).to match_array(
          [
            user_1.id,
            user_2.id
          ]
        )
      end

      context 'when querying website' do
        let(:query) { "https://#{identifier}.com" }

        it 'returns correct user ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              user_3.id
            ]
          )
        end
      end
    end
  end

  describe '#inactive_page_count' do
    let(:owner) { create(:unique_user, :owner) }
    let(:active_collection) { create(:collection, owner_user_id: owner.id, is_active: true) }
    let(:inactive_collection) { create(:collection, owner_user_id: owner.id, is_active: false) }

    before do
      active_collection.works.each { |w| w.update!(owner: owner) }
      inactive_collection.works.each { |w| w.update!(owner: owner) }
    end

    it 'returns 0 when all collections are active' do
      expect(owner.inactive_page_count).to eq(0)
    end

    it 'returns the count of pages in inactive collections' do
      inactive_collection
      active_collection
      expect(owner.inactive_page_count).to eq(owner.page_count - owner.active_page_count)
    end
  end
end
