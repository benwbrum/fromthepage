require 'spec_helper'

describe ScCollectionsController, 'Internet Archive import' do
  include ActiveJob::TestHelper

  let(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:item_url) { 'https://archive.org/details/mcht_c55_massey_26/page/n1/mode/2up' }
  let(:manifest_url) { 'https://iiif.archive.org/iiif/mcht_c55_massey_26/manifest.json' }
  let(:manifest_json) { File.read(Rails.root.join('test_data/iiif/internet_archive/mcht_c55_massey_26_manifest.json')) }

  before do
    allow(IiifHttp).to receive(:sleep)
  end

  describe 'POST import_ia' do
    it 'requires a signed-in user' do
      post sc_collections_import_ia_path, params: { ia_url: item_url }

      expect(response).to redirect_to(dashboard_path)
    end

    context 'when signed in' do
      before { login_as owner }

      it 'redirects to the IIIF import for the item manifest' do
        post sc_collections_import_ia_path, params: { ia_url: item_url }

        expect(response).to redirect_to(
          sc_collections_import_path(at_id: manifest_url, source: 'internet_archive', source_url: item_url)
        )
      end

      it 'keeps the target collection' do
        post sc_collections_import_ia_path, params: { ia_url: item_url, collection_id: collection.slug }

        expect(response).to redirect_to(
          sc_collections_import_path(at_id: manifest_url, collection_id: collection.slug,
                                     source: 'internet_archive', source_url: item_url)
        )
      end

      it 'asks for a URL when none is given' do
        post sc_collections_import_ia_path, params: { ia_url: '' }

        expect(response).to redirect_to(dashboard_owner_path)
        expect(flash[:error]).to eq(I18n.t('sc_collections.import_ia.please_enter_url'))
      end

      it 'rejects URLs that are not archive.org item pages' do
        post sc_collections_import_ia_path, params: { ia_url: 'https://example.com/details/mcht_c55_massey_26' }

        expect(response).to redirect_to(dashboard_owner_path)
        expect(flash[:error]).to eq(I18n.t('sc_collections.import_ia.please_enter_valid_url'))
      end
    end
  end

  describe 'GET import' do
    before { login_as owner }

    it 'shows the manifest with the option to import its annotation text' do
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest_json)

      get sc_collections_import_path(at_id: manifest_url, source: 'internet_archive', source_url: item_url)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Letter from Harry Massey to Barbara Massey')
      expect(response.body).to include('annotation_ocr')
    end

    it 'explains when the Internet Archive manifest cannot be loaded' do
      stub_request(:get, manifest_url).to_return(status: 502)

      get sc_collections_import_path(at_id: manifest_url, source: 'internet_archive', source_url: item_url)

      expect(response).to be_redirect
      expect(flash[:error]).to eq(
        I18n.t('sc_collections.import.no_internet_archive_manifest_exist', url: item_url)
      )
      expect(a_request(:get, manifest_url)).to have_been_made.times(IiifHttp::ATTEMPTS)
    end
  end

  describe 'POST convert_manifest' do
    before do
      login_as owner
      stub_request(:get, manifest_url).to_return(status: 200, body: manifest_json)
    end

    def convert(extra_params = {})
      post sc_collections_convert_manifest_path,
           params: { at_id: manifest_url, sc_manifest: { collection_id: collection.id } }.merge(extra_params)
      collection.works.reload.last
    end

    it 'creates a work with a page per canvas and queues the annotation text import' do
      work = nil
      expect { work = convert(annotation_ocr: '1') }.to have_enqueued_job(Work::ImportAnnotationTextJob)

      expect(work.title).to eq('Letter from Harry Massey to Barbara Massey [Jan. 01, 1940]')
      expect(work.ocr_correction).to be(true)
      expect(work.pages.map { |page| page.sc_canvas.sc_canvas_id }).to eq(
        ['https://iiif.archive.org/iiif/mcht_c55_massey_26$0/canvas',
         'https://iiif.archive.org/iiif/mcht_c55_massey_26$1/canvas']
      )
      expect(Work::ImportAnnotationTextJob).to have_been_enqueued.with(user_id: owner.id, work_id: work.id)
      expect(flash[:notice]).to eq(I18n.t('sc_collections.convert_manifest.annotation_text_is_being_imported'))
    end

    it 'does not import annotation text unless asked' do
      work = nil
      expect { work = convert }.not_to have_enqueued_job(Work::ImportAnnotationTextJob)

      expect(work.pages.count).to eq(2)
      expect(work.ocr_correction).to be(false)
    end
  end
end
