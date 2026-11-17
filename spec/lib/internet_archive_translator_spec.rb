require 'spec_helper'
require 'internet_archive_translator'

describe InternetArchiveTranslator do
  describe '.ia_url_to_iiif' do
    {
      'https://archive.org/details/b29000427_0001' => 'b29000427_0001',
      'https://archive.org/details/b29000427_0001/page/n13/mode/2up' => 'b29000427_0001',
      'https://www.archive.org/details/lettertosamuelma00estl' => 'lettertosamuelma00estl',
      'http://archive.org/details/mcht_c55_massey_26/' => 'mcht_c55_massey_26',
      'https://archive.org/details/mcht_c55_massey_26?q=massey' => 'mcht_c55_massey_26',
      'https://ARCHIVE.org/details/ms-500.full' => 'ms-500.full',
      "  https://archive.org/details/b29000427_0001\n" => 'b29000427_0001'
    }.each do |url, identifier|
      it "maps #{url.strip} to the manifest for #{identifier}" do
        expect(described_class.ia_url_to_iiif(url))
          .to eq("https://iiif.archive.org/iiif/#{identifier}/manifest.json")
      end
    end

    [
      'https://archive.org/search?query=massey',
      'https://archive.org/details/',
      'https://archive.org/details/bad%2Fidentifier',
      'https://example.com/details/b29000427_0001',
      'https://archive.org.example.com/details/b29000427_0001',
      'ftp://archive.org/details/b29000427_0001',
      'not a url',
      ''
    ].each do |url|
      it "rejects #{url.inspect}" do
        expect { described_class.ia_url_to_iiif(url) }.to raise_error(ArgumentError)
      end
    end
  end
end
