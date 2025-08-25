require 'spec_helper'

describe Page do
  #   context "associations" do
  #     it { should belong_to(:article) }
  #   end

  #   context "validations" do
  #     it { should validate_inclusion_of(:deed_type).in_array(DeedType.all_types) }
  #   end

  describe '#validate_blank_page' do
    let(:page) { build_stubbed(:page) }
    it 'sets :blank' do
      page.status = :blank
      page.validate_blank_page

      expect(page.status_blank?).to be_truthy
    end
    it 'keeps :blank when text is blank' do
      page.status = :blank
      page.validate_blank_page

      page.source_text = ''

      expect(page.status_blank?).to be_truthy
    end
    it 'resets page status if empty and not marked blank' do
      page.status = :transcribed
      page.source_text = ''

      page.validate_blank_page

      expect(page.status_new?).to be_truthy
    end
    it 'does not reset page status is text is not empty' do
      page.status = :blank
      page.source_text = 'Testing'

      page.validate_blank_page

      expect(page.status_blank?).to be_truthy
    end
  end

  context 'es_search' do
    let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

    let!(:owner) { create(:unique_user, :owner) }
    let!(:collection) { create(:collection, owner_user_id: owner.id) }
    let!(:restricted_collection) { create(:collection, owner_user_id: owner.id, restricted: true) }
    let!(:docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :public) }
    let!(:restricted_docset) { create(:document_set, collection_id: restricted_collection.id, owner_user_id: owner.id, visibility: :private) }

    let!(:public_work) { create(:work, collection_id: collection.id, owner_user_id: owner.id) }
    let!(:public_page) { create(:page, title: identifier, work_id: public_work.id) }

    let!(:restricted_work) { create(:work, collection_id: restricted_collection.id, owner_user_id: owner.id) }
    let!(:restricted_page) { create(:page, work_id: restricted_work.id) }

    let!(:restricted_col_public_set_work) { create(:work, collection_id: restricted_collection.id, owner_user_id: owner.id) }
    let!(:restricted_col_public_set_page) { create(:page, source_text: "<div>#{identifier}</div>", work_id: restricted_col_public_set_work.id) }

    let!(:restricted_col_set_work) { create(:work, collection_id: restricted_collection.id, owner_user_id: owner.id) }
    let!(:restricted_col_set_page) { create(:page, title: identifier, work_id: restricted_col_set_work.id) }

    let!(:other_user) { create(:unique_user, :owner) }
    let!(:other_collection) { create(:collection, owner_user_id: other_user.id) }
    let!(:other_restricted_collection) { create(:collection, owner_user_id: other_user.id, restricted: true) }

    let!(:other_public_work) { create(:work, collection_id: other_collection.id, owner_user_id: other_user.id) }
    let!(:other_public_page) { create(:page, title: identifier, work_id: other_public_work.id) }

    let!(:other_restricted_work) { create(:work, collection_id: other_restricted_collection.id, owner_user_id: other_user.id) }
    let!(:other_restricted_page) { create(:page, title: identifier, work_id: other_restricted_work.id) }

    # Set work_id to nil in before_block to avoid callback errors
    let!(:no_work_page) { create(:page, title: identifier, work_id: public_work.id) }

    let!(:no_col_work) { create(:work, collection_id: nil, owner_user_id: other_user.id) }
    let!(:no_col_page) { create(:page, work_id: no_col_work.id) }

    let(:records) do
      [
        owner,
        collection,
        restricted_collection,
        docset,
        restricted_docset,
        public_work,
        public_page,
        restricted_work,
        restricted_page,
        restricted_col_public_set_work,
        restricted_col_public_set_page,
        restricted_col_set_work,
        restricted_col_set_page,
        other_user,
        other_collection,
        other_restricted_collection,
        other_public_work,
        other_public_page,
        other_restricted_work,
        other_restricted_page,
        no_work_page,
        no_col_work,
        no_col_page
      ]
    end

    before(:each) do
      stub_const('ELASTIC_ENABLED', true)

      PagesIndex.purge
      records.each(&:save!)

      no_work_page.update_column(:work_id, nil)
      restricted_page.update_column(:search_text, identifier)
      docset.works << restricted_col_public_set_work
      restricted_docset.works << restricted_col_set_work

      PagesIndex.import [
        no_work_page.reload,
        restricted_page.reload,
        restricted_col_public_set_page.reload,
        restricted_col_set_page.reload
      ]
    end

    after(:each) do
      stub_const('ELASTIC_ENABLED', true)

      no_work_page.update_column(:work_id, public_work.id)
      no_work_page.reload

      records.reverse.each(&:destroy!)
      PagesIndex.purge
    end

    describe '#self.es_search' do
      let(:user) { nil }

      let(:es_search) { described_class.es_search(query: identifier, user: user, is_public: true) }

      context 'when not logged in' do
        it 'returns correct page ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_page.id,
              restricted_col_public_set_page.id,
              other_public_page.id,
              no_work_page.id
            ]
          )
        end
      end

      context 'when logged in as owner' do
        let(:user) { owner }

        it 'returns correct page ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              public_page.id,
              restricted_page.id,
              restricted_col_public_set_page.id,
              restricted_col_set_page.id,
              other_public_page.id,
              no_work_page.id
            ]
          )
        end
      end

      context 'when logged in as other_user and is blocked on public_collection' do
        let(:user) { other_user }

        before do
          collection.blocked_users << other_user
        end

        it 'returns correct page ids' do
          expect(es_search.pluck("_id").map(&:to_i)).to match_array(
            [
              restricted_col_public_set_page.id,
              other_public_page.id,
              other_restricted_page.id,
              no_work_page.id
            ]
          )
        end
      end
    end
  end

  describe '#image_url_for_download' do
    context 'when page has base_image with deployment path' do
      let(:page) { build_stubbed(:page, :with_image) }

      before do
        # Ensure no sc_canvas or ia_leaf to test the local image scenario
        allow(page).to receive(:sc_canvas).and_return(nil)
        allow(page).to receive(:ia_leaf).and_return(nil)

        # Simulate a base_image with deployment path like the issue shows
        page.base_image = '/home/fromthepage/deployment/releases/20250514221152/public/images/uploaded/32197883/page_0001.jpg'

        # Mock the default_url_options that would be set in production
        allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return({ host: 'fromthepage.com' })
      end

      it 'converts deployment path to web URL correctly' do
        result = page.image_url_for_download

        # Should not contain the deployment path
        expect(result).not_to include('/home/fromthepage/deployment/releases/')

        # Should start with https://fromthepage.com for local images
        expect(result).to start_with('https://fromthepage.com')

        # Should contain the correct image path relative to public
        expect(result).to include('/images/uploaded/32197883/page_0001.jpg')

        # Should be the complete expected URL
        expect(result).to eq('https://fromthepage.com/images/uploaded/32197883/page_0001.jpg')
      end
    end

    context 'when page has sc_canvas (IIIF image)' do
      let(:sc_canvas) { double('sc_canvas', sc_resource_id: 'https://iiif.durham.ac.uk/iiif/trifle/32150/t1/mg/73/t1mg732d945c/c449d8a03531bef78218f0b3f3db4f01.jp2/full/full/0/default.jpg') }
      let(:page) { build_stubbed(:page) }

      before do
        allow(page).to receive(:sc_canvas).and_return(sc_canvas)
      end

      it 'returns sc_canvas resource id as-is (external IIIF URLs should not be converted)' do
        result = page.image_url_for_download
        expect(result).to eq('https://iiif.durham.ac.uk/iiif/trifle/32150/t1/mg/73/t1mg732d945c/c449d8a03531bef78218f0b3f3db4f01.jp2/full/full/0/default.jpg')

        # IIIF images should not be converted to fromthepage.com URLs
        expect(result).not_to start_with('https://fromthepage.com')
      end
    end

    context 'when page has ia_leaf' do
      let(:ia_leaf) { double('ia_leaf', facsimile_url: 'https://archive.org/image/123') }
      let(:page) { build_stubbed(:page) }

      before do
        allow(page).to receive(:sc_canvas).and_return(nil)
        allow(page).to receive(:ia_leaf).and_return(ia_leaf)
      end

      it 'returns ia_leaf facsimile url' do
        expect(page.image_url_for_download).to eq('https://archive.org/image/123')
      end
    end
  end
end
