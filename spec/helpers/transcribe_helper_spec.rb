require 'spec_helper'

RSpec.describe TranscribeHelper, type: :helper do
  describe '#get_active_tab_path' do
    let(:owner) { 'owner' }
    let(:collection) { 'collection' }
    let(:work) { 'work' }
    let(:item) { 'page' }

    before do
      allow(helper).to receive(:collection_display_page_path).with(owner, collection, work, item).and_return('/display')
      allow(helper).to receive(:collection_transcribe_page_path).with(owner, collection, work, item).and_return('/transcribe')
      allow(helper).to receive(:collection_translate_page_path).with(owner, collection, work, item).and_return('/translate')
      allow(helper).to receive(:collection_help_page_path).with(owner, collection, work, item).and_return('/help')
      allow(helper).to receive(:collection_page_version_path).with(owner, collection, work, item).and_return('/version')
      allow(helper).to receive(:collection_edit_page_path).with(owner, collection, work, item).and_return('/edit')
    end

    it 'returns the route for each known tab and falls back to transcribe' do
      expect(helper.get_active_tab_path('display', owner, collection, work, item)).to eq('/display')
      expect(helper.get_active_tab_path('transcribe', owner, collection, work, item)).to eq('/transcribe')
      expect(helper.get_active_tab_path('transcribe-translate', owner, collection, work, item)).to eq('/translate')
      expect(helper.get_active_tab_path('transcribe-help', owner, collection, work, item)).to eq('/help')
      expect(helper.get_active_tab_path('page_version', owner, collection, work, item)).to eq('/version')
      expect(helper.get_active_tab_path('page', owner, collection, work, item)).to eq('/edit')
      expect(helper.get_active_tab_path('unknown', owner, collection, work, item)).to eq('/transcribe')
    end
  end

  describe '#osd_source' do
    let(:work) { create(:work) }

    it 'uses the local image service for an Active Storage image' do
      page = create(:page, :with_image, work: work)

      expect(helper.send(:osd_source, page, work)).to eq(["http://test.host/image-service/#{page.id}/info.json"])
    end

    it 'uses the local image service for a legacy image' do
      page = create(:page, :with_legacy_image, work: work)

      expect(helper.send(:osd_source, page, work)).to eq(["http://test.host/image-service/#{page.id}/info.json"])
    end

    it 'retains external IIIF sources' do
      sc_page = instance_double(Page, sc_canvas: double(iiif_image_info_url: 'https://example.org/iiif/sc/info.json'))
      ia_page = instance_double(Page, sc_canvas: nil, ia_leaf: double(iiif_image_info_url: 'https://archive.org/iiif/ia/info.json'))

      expect(helper.send(:osd_source, sc_page, work)).to eq(['https://example.org/iiif/sc/info.json'])
      expect(helper.send(:osd_source, ia_page, work)).to eq(['https://archive.org/iiif/ia/info.json'])
    end
  end
end
