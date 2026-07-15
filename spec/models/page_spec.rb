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
        other_restricted_page
      ]
    end

    before(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      PagesIndex.purge
      records.each(&:save!)

      restricted_page.update_column(:search_text, identifier)
      docset.works << restricted_col_public_set_work
      restricted_docset.works << restricted_col_set_work

      PagesIndex.import [
        restricted_page.reload,
        restricted_col_public_set_page.reload,
        restricted_col_set_page.reload
      ]
    end

    after(:each) do
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      records.reverse.each(&:destroy!)
      PagesIndex.purge

      VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
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
              other_public_page.id
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
              other_public_page.id
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
              other_restricted_page.id
            ]
          )
        end
      end
    end
  end

  describe '#image_url_for_download' do
    context 'when page has base_image with deployment path' do
      let(:page) { build_stubbed(:page, :with_legacy_image) }

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

    context 'when page has base_image with special characters' do
      let(:page) { build_stubbed(:page, :with_legacy_image) }

      before do
        # Ensure no sc_canvas or ia_leaf to test the local image scenario
        allow(page).to receive(:sc_canvas).and_return(nil)
        allow(page).to receive(:ia_leaf).and_return(nil)

        # Simulate a base_image with special characters like # and spaces
        page.base_image = '/home/fromthepage/deployment/releases/20250514221152/public/images/uploaded/32237431/ASS 642 #11 f. 1r.jpeg'

        # Mock the default_url_options that would be set in production
        allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return({ host: 'fromthepage.com' })
      end

      it 'converts path with special characters to properly encoded URL' do
        result = page.image_url_for_download

        # Should not contain the deployment path
        expect(result).not_to include('/home/fromthepage/deployment/releases/')

        # Should start with https://fromthepage.com for local images
        expect(result).to start_with('https://fromthepage.com')

        # Should contain URL-encoded special characters
        expect(result).to include('ASS%20642%20%2311%20f.%201r.jpeg')

        # Should be the complete expected URL with proper encoding
        expect(result).to eq('https://fromthepage.com/images/uploaded/32237431/ASS%20642%20%2311%20f.%201r.jpeg')
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

  describe '#thumbnail_url' do
    context 'when page has base_image with special characters' do
      let(:page) { build_stubbed(:page) }

      before do
        allow(page).to receive(:sc_canvas).and_return(nil)
        allow(page).to receive(:ia_leaf).and_return(nil)
        allow(page).to receive(:thumbnail_image).and_return('/public/images/uploaded/32237431/ASS 642 #11 f. 1r_thumb.jpeg')
      end

      it 'returns URL encoded thumbnail path' do
        # Include the ApplicationHelper to access file_to_url
        page.extend(ApplicationHelper)
        result = page.thumbnail_url
        expect(result).to eq('/images/uploaded/32237431/ASS%20642%20%2311%20f.%201r_thumb.jpeg')
      end
    end

    context 'when page has sc_canvas but no local base_image' do
      let(:sc_canvas) { double('sc_canvas',
        sc_service_id: 'https://iiif.example.com/image/1',
        sc_service_context: 'http://iiif.io/api/image/2/context.json',
        thumbnail_url: 'https://iiif.example.com/image/1/full/100,/0/default.jpg') }
      let(:page) { build_stubbed(:page) }

      before do
        allow(page).to receive(:sc_canvas).and_return(sc_canvas)
        allow(page).to receive(:ia_leaf).and_return(nil)
      end

      it 'returns the IIIF canvas thumbnail URL' do
        result = page.thumbnail_url
        expect(result).to eq('https://iiif.example.com/image/1/full/100,/0/default.jpg')
      end
    end

    context 'when page has sc_canvas and a local base_image (e.g. after rotation)' do
      let(:sc_canvas) { double('sc_canvas',
        sc_service_id: 'https://iiif.example.com/image/1',
        sc_service_context: 'http://iiif.io/api/image/2/context.json',
        thumbnail_url: 'https://iiif.example.com/image/1/full/100,/0/default.jpg') }
      # build_stubbed properly sets base_image in the attribute hash, so self[:base_image] works correctly
      let(:page) { build_stubbed(:page, base_image: "#{Rails.root}/public/images/working/upload/123.jpg") }

      before do
        allow(page).to receive(:sc_canvas).and_return(sc_canvas)
        allow(page).to receive(:ia_leaf).and_return(nil)
        allow(page).to receive(:thumbnail_image).and_return("#{Rails.root}/public/images/working/upload/123_thumb.jpg")
      end

      it 'returns the local thumbnail URL instead of the IIIF canvas URL' do
        # build_stubbed does not fully replicate included modules, so we extend ApplicationHelper
        # to make file_to_url available (same pattern as the existing test above)
        page.extend(ApplicationHelper)
        result = page.thumbnail_url
        expect(result).to eq('/images/working/upload/123_thumb.jpg')
        expect(result).not_to include('iiif.example.com')
      end
    end
  end

  describe '#ai_plaintext_has_emoji_placeholders?' do
    let(:page) { build_stubbed(:page) }

    context 'when ai_plaintext contains emoji placeholders' do
      before do
        allow(page).to receive(:ai_plaintext).and_return("This is some text with 🤔 placeholder")
      end

      it 'returns true' do
        expect(page.ai_plaintext_has_emoji_placeholders?).to be true
      end
    end

    context 'when ai_plaintext does not contain emoji placeholders' do
      before do
        allow(page).to receive(:ai_plaintext).and_return("This is some text without placeholders")
      end

      it 'returns false' do
        expect(page.ai_plaintext_has_emoji_placeholders?).to be false
      end
    end

    context 'when ai_plaintext is empty' do
      before do
        allow(page).to receive(:ai_plaintext).and_return("")
      end

      it 'returns false' do
        expect(page.ai_plaintext_has_emoji_placeholders?).to be false
      end
    end
  end

  describe '#field_ai_draft_available?' do
    let(:page) { build_stubbed(:page) }
    let(:collection) { build_stubbed(:collection) }

    before do
      allow(page).to receive(:collection).and_return(collection)
    end

    context 'when the collection is not field based' do
      before do
        allow(page).to receive(:field_based).and_return(false)
      end

      it 'returns false' do
        expect(page.field_ai_draft_available?).to be false
      end
    end

    context 'when the collection is field based' do
      before do
        allow(page).to receive(:field_based).and_return(true)
      end

      context 'when there is no finished ai transcription' do
        before do
          allow(page).to receive(:finished_ai_transcription).and_return(nil)
        end

        it 'returns false' do
          expect(page.field_ai_draft_available?).to be false
        end
      end

      context 'when there is a finished ai transcription' do
        before do
          allow(page).to receive(:finished_ai_transcription).and_return(build_stubbed(:ai_transcription, status: :finished))
        end

        context 'when the collection has a spreadsheet field' do
          before do
            allow(collection).to receive_message_chain(:transcription_fields, :where, :exists?).and_return(true)
          end

          it 'returns false' do
            expect(page.field_ai_draft_available?).to be false
          end
        end

        context 'when the collection has no spreadsheet field' do
          before do
            allow(collection).to receive_message_chain(:transcription_fields, :where, :exists?).and_return(false)
          end

          it 'returns true' do
            expect(page.field_ai_draft_available?).to be true
          end
        end
      end
    end
  end

  describe '#finished_ai_transcriptions_by_engine' do
    let(:page) { create(:page, work: create(:work)) }

    it 'returns an empty hash when there are no finished ai transcriptions' do
      create(:ai_transcription, page: page, status: :new, model: 'gemini-3-pro-preview')

      expect(page.finished_ai_transcriptions_by_engine).to eq({})
    end

    it 'excludes the alto engine' do
      create(:ai_transcription, page: page, status: :finished, model: AiTranscription::ALTO_MODEL)

      expect(page.finished_ai_transcriptions_by_engine).to eq({})
    end

    it 'returns the latest finished transcription for each engine' do
      older_gemini = create(:ai_transcription, page: page, status: :finished, model: 'gemini-3-pro-preview', created_at: 2.days.ago)
      newer_gemini = create(:ai_transcription, page: page, status: :finished, model: 'gemini-3-pro-preview', created_at: 1.day.ago)
      claude = create(:ai_transcription, page: page, status: :finished, model: 'claude-sonnet')
      create(:ai_transcription, page: page, status: :error, model: 'claude-sonnet')

      result = page.finished_ai_transcriptions_by_engine

      expect(result).to eq({ 'gemini' => newer_gemini, 'claude' => claude })
      expect(result['gemini']).not_to eq(older_gemini)
    end
  end
end
