require 'spec_helper'

RSpec.describe ScCollection do
  describe '.collection_for_at_id' do
    let(:collection_url) { 'https://example.com/collection' }
    let(:collection_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => collection_url,
        '@type' => 'sc:Collection',
        'label' => 'Example Collection',
        'manifests' => []
      }.to_json
    end

    it 'trims whitespace from at_id before fetching' do
      expect(URI).to receive(:open).with(collection_url).and_return(double(read: collection_json))

      sc_collection = described_class.collection_for_at_id("  #{collection_url} ")

      expect(sc_collection.at_id).to eq(collection_url)
    end
  end
end
