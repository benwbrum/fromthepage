require 'spec_helper'

describe Collection do
  describe 'validations' do
    context 'html validations' do
      let(:invalid_html) { '<p>Missing end tags' }
      let(:valid_html) { "<p>With \n special character &\n\n</p>" }
      let(:collection) { create(:collection) }

      it 'validates html syntax' do
        collection.intro_block = invalid_html
        expect(collection.valid?).to be_falsey

        collection.intro_block = valid_html
        expect(collection.valid?).to be_truthy
      end
    end
  end

  describe '#is_public' do
    it 'returns true if a collection is not restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: false)

      expect(collection.is_public).to be true
    end

    it 'returns false if a collection is restricted' do
      user = build_stubbed(:user)
      collection = build_stubbed(:collection, owner_user_id: user.id, restricted: true)

      expect(collection.is_public).to be false
    end
  end

  describe '#set_next_untranscribed_page' do
    let(:collection){ create(:collection, works: []) }
    let(:work){ create(:work, collection_id: collection.id) }
    it "sets nil with no works" do
      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(nil)
    end
    it "sets to untranscribed page in work" do
      page = create(:page, work_id: work.id)

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(page)

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(page)
    end
    it "sets to nil for no works with untranscribed pages" do
      create(:page, work_id: work.id, status: :transcribed)

      work.set_next_untranscribed_page
      expect(work.next_untranscribed_page).to eq(nil)

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(nil)
    end
    it "sets to NUP of work with least complete" do
      create(:page, work_id: work.id, status: :transcribed)
      work_incomplete = create(:work, collection_id: collection.id)
      page_incomplete = create(:page, status: :new, work_id: work_incomplete.id)
      create(:page, status: :transcribed, work_id: work_incomplete.id)

      work.set_next_untranscribed_page
      work.save!
      work_incomplete.set_next_untranscribed_page
      work_incomplete.save!

      collection.set_next_untranscribed_page
      expect(collection.next_untranscribed_page).to eq(page_incomplete)
    end
  end

  context 'OCR Settings' do
    before :each do
      DatabaseCleaner.start
    end
    after :each do
      DatabaseCleaner.clean
    end

    let(:work_no_ocr) { create(:work) }
    let(:work_ocr)    { create(:work) }

    let(:collection) { create(:collection, works: [work_no_ocr, work_ocr]) }
    describe '#enable_ocr' do
      it 'Enables OCR for all works' do
        collection.enable_ocr
        all_enabled = collection.works.all? {|w| w.ocr_correction }
        expect(all_enabled)
      end
    end
    describe '#disable_ocr' do
      it 'Disables OCR for all works' do
        collection.disable_ocr
        all_disabled = collection.works.none? {|w| w.ocr_correction }
        expect(all_disabled)
      end
    end
  end

  describe '#enable_messageboards' do
    context 'when messageboard_group is nil' do
      let(:collection) { create(:collection, messageboard_group: nil) }

      it 'creates a messageboard group and default messageboards' do
        expect {
          collection.enable_messageboards
        }.to change(Thredded::MessageboardGroup, :count).by(1)
         .and change(Thredded::Messageboard, :count).by(2)

        expect(collection.messageboards_enabled).to be_truthy

        # Test disabling
        collection.disable_messageboards
        expect(collection.messageboards_enabled).to be_falsey
        # Manually set to nil without deleting
        collection.messageboard_group = nil
        collection.save

        # Enable again, but will not increase count
        expect {
          collection.enable_messageboards
        }.not_to change(Thredded::MessageboardGroup, :count)
      end
    end
  end

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:public_collection) { create(:collection, title: identifier, owner_user_id: owner.id) }
    let!(:restricted_collection) { create(:collection, title: identifier, owner_user_id: owner.id, restricted: true) }
    let!(:public_updated_to_restricted_collection) { create(:collection, title: identifier, owner_user_id: owner.id) }

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_public_collection) { create(:collection, title: identifier, owner_user_id: other_user.id) }
    let!(:other_restricted_collection) { create(:collection, title: identifier, owner_user_id: other_user.id, restricted: true) }

    # We also query by intro_block, so this tests that
    let!(:no_owner_public_collection) { create(:collection, intro_block: "<div>#{identifier}</div>", owner_user_id: nil) }

    let(:records) do
      [
        owner,
        public_collection,
        restricted_collection,
        public_updated_to_restricted_collection,
        other_user,
        other_public_collection,
        other_restricted_collection,
        no_owner_public_collection
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.purge
      records.each(&:save!)

      public_updated_to_restricted_collection.update!(restricted: true)
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      CollectionsIndex.purge
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct collection ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_collection.id,
              other_public_collection.id,
              no_owner_public_collection.id
            ]
          )
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct collection ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_collection.id,
              restricted_collection.id,
              public_updated_to_restricted_collection.id,
              other_public_collection.id,
              no_owner_public_collection.id
            ]
          )
        end
      end

      context 'when logged in as other_user and is blocked on public_collection' do
        let(:user) { other_user }

        before do
          public_collection.blocked_users << other_user
        end

        it 'returns correct collection ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              other_public_collection.id,
              other_restricted_collection.id,
              no_owner_public_collection.id
            ]
          )
        end
      end
    end
  end

  describe '#default_orientation' do
    context 'when default_orientation is explicitly set' do
      it 'returns the set value' do
        collection = build(:collection, default_orientation: 'vertical-rl')
        expect(collection.default_orientation).to eq('vertical-rl')
      end
    end

    context 'when default_orientation is not set' do
      it 'returns ttb for field_based collections' do
        collection = build(:collection, field_based: true, default_orientation: nil)
        expect(collection.default_orientation).to eq('ttb')
      end

      it 'returns ltr for non-field_based collections' do
        collection = build(:collection, field_based: false, default_orientation: nil)
        expect(collection.default_orientation).to eq('ltr')
      end
    end
  end

  describe '#writing_mode' do
    it 'returns vertical-rl for vertical-rl orientation' do
      collection = build(:collection, text_orientation: 'vertical-rl')
      expect(collection.writing_mode).to eq('vertical-rl')
    end

    it 'returns vertical-lr for vertical-lr orientation' do
      collection = build(:collection, text_orientation: 'vertical-lr')
      expect(collection.writing_mode).to eq('vertical-lr')
    end

    it 'returns vertical-rl for legacy ttb orientation' do
      collection = build(:collection, text_orientation: 'ttb')
      expect(collection.writing_mode).to eq('vertical-rl')
    end

    it 'returns horizontal-tb for rtl orientation' do
      collection = build(:collection, text_orientation: 'rtl')
      expect(collection.writing_mode).to eq('horizontal-tb')
    end

    it 'returns horizontal-tb for ltr orientation' do
      collection = build(:collection, text_orientation: 'ltr')
      expect(collection.writing_mode).to eq('horizontal-tb')
    end

    it 'returns horizontal-tb for nil orientation' do
      collection = build(:collection, text_orientation: nil)
      expect(collection.writing_mode).to eq('horizontal-tb')
    end
  end
end
