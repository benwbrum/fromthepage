require 'spec_helper'

RSpec.describe ScCollection do
  describe '.collection_for_at_id' do
    let(:collection_url) { 'https://example.com/collection' }
    let(:collection_json) { '{"@id":"https://example.com/collection","@type":"sc:Collection","label":"Example"}' }
    let(:service) { double(label: 'Example Collection') }

    it 'trims whitespace from at_id before fetching' do
      allow(URI).to receive(:open).with(collection_url).and_return(double(read: collection_json))
      allow(IIIF::Service).to receive(:parse).with(collection_json).and_return(service)
      allow(service).to receive(:[]).with('@id').and_return(collection_url)

      relation = instance_double(ActiveRecord::Relation)
      allow(described_class).to receive(:where).with(at_id: collection_url).and_return(relation)
      allow(relation).to receive(:first).and_return(nil)
      sc_collection_instance = described_class.new
      allow(described_class).to receive(:new).and_return(sc_collection_instance)
      allow(sc_collection_instance).to receive(:save!).and_return(true)

      sc_collection = described_class.collection_for_at_id("  #{collection_url} ")

      expect(sc_collection.at_id).to eq(collection_url)
    end
  end
end
