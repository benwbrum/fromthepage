require 'spec_helper'

describe ApplicationHelper do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }

  describe '#set_social_media_meta_tags' do
    let(:title) { 'Test Title' }
    let(:description) { 'Test Description' }
    let(:image_url) { 'http://example.com/image.jpg' }
    let(:url) { 'http://example.com/page' }

    before do
      # Mock request context for helper
      allow(helper).to receive(:defined?).with(:request).and_return(true)
      request_double = double(
        original_url: url,
        protocol: 'http://',
        host_with_port: 'example.com',
        present?: true
      )
      allow(helper).to receive(:request).and_return(request_double)
      allow(helper).to receive(:content_for)
      # Allow both respond_to? calls that might be made
      allow(helper).to receive(:respond_to?).with(:request).and_return(true)
      allow(helper).to receive(:respond_to?).with(:asset_url).and_return(true)
      allow(helper).to receive(:asset_url).with('logo.png').and_return('/assets/logo-123.png')
    end

    it 'sets Open Graph meta tags' do
      expect(helper).to receive(:content_for).with(:og_title, title)
      expect(helper).to receive(:content_for).with(:og_description, description)
      expect(helper).to receive(:content_for).with(:og_type, 'website')
      expect(helper).to receive(:content_for).with(:og_url, url)

      helper.set_social_media_meta_tags(title: title, description: description, url: url)
    end

    it 'sets Twitter Card meta tags' do
      expect(helper).to receive(:content_for).with(:twitter_card, 'summary_large_image')
      expect(helper).to receive(:content_for).with(:twitter_title, title)
      expect(helper).to receive(:content_for).with(:twitter_description, description)

      helper.set_social_media_meta_tags(title: title, description: description)
    end

    it 'sets image meta tags when image provided' do
      expect(helper).to receive(:content_for).with(:og_image, image_url)
      expect(helper).to receive(:content_for).with(:twitter_image, image_url)

      helper.set_social_media_meta_tags(title: title, description: description, image_url: image_url)
    end

    it 'sets oEmbed discovery URLs when request is available' do
      expect(helper).to receive(:content_for).with(:oembed_json_url, anything)
      expect(helper).to receive(:content_for).with(:oembed_xml_url, anything)

      helper.set_social_media_meta_tags(title: title, description: description)
    end
  end

  describe '#collection_image_url' do
    it 'returns nil when collection is nil' do
      expect(helper.collection_image_url(nil)).to be_nil
    end

    it 'returns nil when collection has no picture' do
      expect(helper.collection_image_url(collection)).to be_nil
    end

    it 'returns absolute URL when collection has picture' do
      allow(collection).to receive(:picture).and_return('/path/to/image.jpg')
      allow(helper).to receive(:absolute_url).with('/path/to/image.jpg').and_return('http://example.com/path/to/image.jpg')
      
      expect(helper.collection_image_url(collection)).to eq('http://example.com/path/to/image.jpg')
    end
  end

  describe '#work_image_url' do
    it 'returns nil when work is nil' do
      expect(helper.work_image_url(nil)).to be_nil
    end

    it 'returns nil when work has no picture' do
      expect(helper.work_image_url(work)).to be_nil
    end

    it 'returns absolute URL when work has picture' do
      allow(work).to receive(:picture).and_return('/path/to/work.jpg')
      allow(helper).to receive(:absolute_url).with('/path/to/work.jpg').and_return('http://example.com/path/to/work.jpg')
      
      expect(helper.work_image_url(work)).to eq('http://example.com/path/to/work.jpg')
    end
  end

  describe '#page_image_url' do
    it 'returns nil when page is nil' do
      expect(helper.page_image_url(nil)).to be_nil
    end

    it 'returns nil when page has no base_image' do
      expect(helper.page_image_url(page)).to be_nil
    end

    it 'returns absolute URL when page has base_image' do
      allow(page).to receive(:base_image).and_return('/path/to/page.jpg')
      allow(helper).to receive(:absolute_url).with('/path/to/page.jpg').and_return('http://example.com/path/to/page.jpg')
      
      expect(helper.page_image_url(page)).to eq('http://example.com/path/to/page.jpg')
    end
  end

  describe '#strip_html_and_truncate' do
    it 'returns empty string for blank text' do
      expect(helper.strip_html_and_truncate(nil)).to eq('')
      expect(helper.strip_html_and_truncate('')).to eq('')
    end

    it 'strips HTML tags' do
      html_text = '<p>Hello <strong>world</strong>!</p>'
      expect(helper.strip_html_and_truncate(html_text)).to eq('Hello world!')
    end

    it 'normalizes whitespace' do
      text = "  Hello   world  \n\n  "
      expect(helper.strip_html_and_truncate(text)).to eq('Hello world')
    end

    it 'truncates long text' do
      long_text = 'a' * 300
      result = helper.strip_html_and_truncate(long_text, length: 50)
      expect(result).to eq("#{'a' * 50}...")
      expect(result.length).to eq(53) # 50 + '...'
    end

    it 'does not truncate short text' do
      short_text = 'Hello world'
      result = helper.strip_html_and_truncate(short_text, length: 50)
      expect(result).to eq('Hello world')
    end
  end

  describe '#absolute_url' do
    before do
      allow(helper).to receive(:defined?).with(:request).and_return(true)
      request_double = double(
        protocol: 'https://',
        host_with_port: 'example.com',
        present?: true
      )
      allow(helper).to receive(:request).and_return(request_double)
      # Allow both respond_to? calls that might be made
      allow(helper).to receive(:respond_to?).with(:request).and_return(true)
      allow(helper).to receive(:respond_to?).with(:asset_url).and_return(true)
    end

    it 'returns blank for blank URL' do
      expect(helper.send(:absolute_url, nil)).to be_nil
      expect(helper.send(:absolute_url, '')).to eq('')
    end

    it 'returns absolute URL unchanged' do
      absolute_url = 'http://example.com/image.jpg'
      expect(helper.send(:absolute_url, absolute_url)).to eq(absolute_url)
    end

    it 'converts relative URL to absolute with request context' do
      relative_url = '/path/to/image.jpg'
      expected = 'https://example.com/path/to/image.jpg'
      expect(helper.send(:absolute_url, relative_url)).to eq(expected)
    end

    it 'handles URL without leading slash' do
      relative_url = 'path/to/image.jpg'
      expected = 'https://example.com/path/to/image.jpg'
      expect(helper.send(:absolute_url, relative_url)).to eq(expected)
    end

    it 'falls back gracefully when request is not available' do
      allow(helper).to receive(:defined?).with(:request).and_return(false)
      allow(helper).to receive(:respond_to?).with(:request).and_return(false)
      allow(helper).to receive(:respond_to?).with(:asset_url).and_return(false)
      
      relative_url = '/path/to/image.jpg'
      expect(helper.send(:absolute_url, relative_url)).to eq(relative_url)
    end
  end
end