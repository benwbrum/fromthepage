require 'spec_helper'

RSpec.describe TranscribeHelper, type: :helper do
  describe '#single_osd_source' do
    let(:image) { double(attached?: true) }
    let(:page) do
      double(id: 42, sc_canvas: nil, ia_leaf: nil, image: image,
             base_width: 2000, base_height: 3000)
    end
    let(:platform) { double(ios?: false) }
    let(:browser) { double(platform: platform, webkit?: false) }
    let(:routes) { Rails.application.routes.url_helpers }

    before do
      allow(helper).to receive(:browser).and_return(browser)
      allow(helper).to receive(:url_for).with(:root).and_return('/')
      allow(routes).to receive(:url_for).with(image).and_return('/direct-image')
      allow(routes).to receive(:rails_storage_proxy_url).with(image).and_return('/proxy-image')
    end

    [[16_385, 3000], [2000, 16_385], [20_208, 26_858], [nil, 16_385]].each do |width, height|
      it "uses riiif for an uploaded image measuring #{width.inspect} by #{height}" do
        allow(page).to receive_messages(base_width: width, base_height: height)

        expect(helper.send(:single_osd_source, page)).to eq('/image-service/42/info.json')
        expect(helper.send(:single_osd_source, page, proxy: true)).to eq('/image-service/42/info.json')
      end
    end

    [[2000, 3000], [16_384, 16_384], [nil, nil]].each do |width, height|
      it "keeps direct and proxy URLs for an uploaded image measuring #{width.inspect} by #{height.inspect}" do
        allow(page).to receive_messages(base_width: width, base_height: height)

        expect(JSON.parse(helper.send(:single_osd_source, page))).to eq('type' => 'image', 'url' => '/direct-image')
        expect(JSON.parse(helper.send(:single_osd_source, page, proxy: true))).to eq('type' => 'image', 'url' => '/proxy-image')
      end
    end

    it 'preserves the iOS WebKit fallback for small images' do
      allow(platform).to receive(:ios?).and_return(true)
      allow(browser).to receive(:webkit?).and_return(true)

      expect(helper.send(:single_osd_source, page)).to eq('/image-service/42/info.json')
    end

    [:sc_canvas, :ia_leaf].each do |source|
      it "preserves the external IIIF source for #{source}" do
        allow(page).to receive(source).and_return(double(iiif_image_info_url: 'https://example.org/info.json'))
        allow(page).to receive_messages(base_width: 20_208, base_height: 26_858)

        expect(helper.send(:single_osd_source, page)).to eq('https://example.org/info.json')
      end
    end

    it 'preserves direct URLs for legacy images' do
      allow(image).to receive(:attached?).and_return(false)
      allow(page).to receive_messages(base_width: 20_208, base_height: 26_858, canonical_facsimile_url: '/legacy-image')
      allow(helper).to receive(:file_to_url).with('/legacy-image').and_return('/legacy-image')

      expect(JSON.parse(helper.send(:single_osd_source, page))).to eq('type' => 'image', 'url' => '/legacy-image')
    end
  end

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
end
