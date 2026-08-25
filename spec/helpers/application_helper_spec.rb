require 'spec_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#relative_time_tag' do
    it 'renders a time tag with datetime, title, and relative text' do
      time = Time.utc(2026, 1, 1, 12, 0, 0)

      html = helper.relative_time_tag(time, class: 'small fglight')

      expect(html).to include('class="small fglight"')
      expect(html).to include('datetime="2026-01-01T12:00:00Z"')
      expect(html).to include('title=')
      expect(html).to match(%r{<time[^>]*>.+</time>})
    end
  end

  describe '#timeago' do
    it 'renders a time tag with datetime and title attributes' do
      time = Time.utc(2026, 1, 1, 12, 0, 0)

      html = helper.timeago(time)

      expect(html).to include('class="timeago"')
      expect(html).to include('datetime="2026-01-01T12:00:00Z"')
      expect(html).to include('title=')
    end
  end

  describe '#file_to_url' do
    context 'with nil filename' do
      it 'returns empty string' do
        expect(helper.file_to_url(nil)).to eq('')
      end
    end

    context 'with empty filename' do
      it 'returns empty string' do
        expect(helper.file_to_url('')).to eq('')
      end
    end

    context 'with simple filename' do
      it 'strips the path before public' do
        filename = '/home/fromthepage/deployment/releases/20250514221152/public/images/uploaded/32197883/page_0001.jpg'
        expect(helper.file_to_url(filename)).to eq('/images/uploaded/32197883/page_0001.jpg')
      end
    end

    context 'with filename containing # character' do
      it 'URL encodes the # character' do
        filename = '/home/fromthepage/deployment/releases/20250514221152/public/images/uploaded/32237431/ASS 642 #11 f. 1r.jpeg'
        expected = '/images/uploaded/32237431/ASS%20642%20%2311%20f.%201r.jpeg'
        expect(helper.file_to_url(filename)).to eq(expected)
      end

      it 'URL encodes the # character in thumbnail filename' do
        filename = '/home/fromthepage/deployment/releases/20250514221152/public/images/uploaded/32237431/ASS 642 #11 f. 1r_thumb.jpeg'
        expected = '/images/uploaded/32237431/ASS%20642%20%2311%20f.%201r_thumb.jpeg'
        expect(helper.file_to_url(filename)).to eq(expected)
      end
    end

    context 'with filename containing spaces' do
      it 'URL encodes spaces' do
        filename = '/var/www/public/images/test file.jpg'
        expected = '/images/test%20file.jpg'
        expect(helper.file_to_url(filename)).to eq(expected)
      end
    end

    context 'with filename containing multiple special characters' do
      it 'URL encodes all special characters' do
        filename = '/var/www/public/images/file with #hash & ampersand.jpg'
        expected = '/images/file%20with%20%23hash%20%26%20ampersand.jpg'
        expect(helper.file_to_url(filename)).to eq(expected)
      end
    end

    context 'with filename path already starting with /' do
      it 'preserves the leading slash' do
        filename = '/images/uploaded/32197883/page_0001.jpg'
        expect(helper.file_to_url(filename)).to eq('/images/uploaded/32197883/page_0001.jpg')
      end
    end
  end
end
