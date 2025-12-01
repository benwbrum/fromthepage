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
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

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
      VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

      stub_const('ELASTIC_ENABLED', true)

      no_work_page.update_column(:work_id, public_work.id)
      no_work_page.reload

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

    context 'when page has base_image with special characters' do
      let(:page) { build_stubbed(:page, :with_image) }

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

  describe '#has_alto? and #valid_alto?' do
    let(:page) { build_stubbed(:page, id: 12345, work_id: 100) }
    let(:alto_path) { File.join(Rails.root, 'public', 'text', '100', '12345_alto.xml') }

    before do
      # Ensure the directory exists
      FileUtils.mkdir_p(File.dirname(alto_path))
    end

    after do
      # Clean up test files
      File.delete(alto_path) if File.exist?(alto_path)
    end

    context 'when ALTO file does not exist' do
      it 'has_alto? returns false' do
        expect(page.has_alto?).to be false
      end

      it 'valid_alto? returns false' do
        expect(page.valid_alto?).to be false
      end
    end

    context 'when ALTO file contains valid ALTO XML' do
      before do
        valid_alto = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <alto xmlns="http://www.loc.gov/standards/alto/ns-v4#">
            <Layout>
              <Page>
                <TextBlock>
                  <TextLine>
                    <String CONTENT="Test"/>
                  </TextLine>
                </TextBlock>
              </Page>
            </Layout>
          </alto>
        XML
        File.write(alto_path, valid_alto)
      end

      it 'has_alto? returns true' do
        expect(page.has_alto?).to be true
      end

      it 'valid_alto? returns true' do
        expect(page.valid_alto?).to be true
      end

      it 'alto_xml returns the file content' do
        expect(page.alto_xml).to include('<alto')
        expect(page.alto_xml).to include('Test')
      end
    end

    context 'when ALTO file contains Transkribus error response' do
      before do
        error_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <errorRepresentation>
            <statusCode>404</statusCode>
            <reasonPhrase>Not Found</reasonPhrase>
            <message>Processing result is not available. Process status is 'FAILED'</message>
          </errorRepresentation>
        XML
        File.write(alto_path, error_xml)
      end

      it 'has_alto? returns false' do
        expect(page.has_alto?).to be false
      end

      it 'valid_alto? returns false' do
        expect(page.valid_alto?).to be false
      end

      it 'alto_xml returns empty string' do
        expect(page.alto_xml).to eq('')
      end
    end

    context 'when ALTO file is empty' do
      before do
        File.write(alto_path, '')
      end

      it 'has_alto? returns false' do
        expect(page.has_alto?).to be false
      end

      it 'valid_alto? returns false' do
        expect(page.valid_alto?).to be false
      end
    end

    context 'when ALTO file contains invalid XML' do
      before do
        File.write(alto_path, '<invalid><xml>')
      end

      it 'has_alto? returns false' do
        expect(page.has_alto?).to be false
      end

      it 'valid_alto? returns false' do
        expect(page.valid_alto?).to be false
      end
    end
  end

  describe '#delete_alto' do
    let(:page) { build_stubbed(:page, id: 12345, work_id: 100) }
    let(:alto_path) { File.join(Rails.root, 'public', 'text', '100', '12345_alto.xml') }

    before do
      FileUtils.mkdir_p(File.dirname(alto_path))
      File.write(alto_path, 'test content')
    end

    it 'deletes the ALTO file if it exists' do
      expect(File.exist?(alto_path)).to be true
      page.delete_alto
      expect(File.exist?(alto_path)).to be false
    end

    it 'does not raise error if file does not exist' do
      File.delete(alto_path)
      expect { page.delete_alto }.not_to raise_error
    end
  end
end
