require 'spec_helper'

RSpec.describe ScManifest, type: :model do
  describe '.detect_manifest_version' do
    context 'with v2 manifest' do
      it 'detects v2 from presentation/2 context' do
        manifest = { '@context' => 'http://iiif.io/api/presentation/2/context.json' }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('2')
      end

      it 'detects v2 from presentation/2 in array context' do
        manifest = { '@context' => ['http://iiif.io/api/presentation/2/context.json'] }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('2')
      end
    end

    context 'with v3 manifest' do
      it 'detects v3 from presentation/3 context' do
        manifest = { '@context' => 'http://iiif.io/api/presentation/3/context.json' }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('3')
      end

      it 'detects v3 from presentation/3 in array context' do
        manifest = { '@context' => ['http://iiif.io/api/presentation/3/context.json', 'http://www.w3.org/ns/anno.jsonld'] }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('3')
      end

      it 'detects v3 when presentation/3 is not first in array context' do
        manifest = { '@context' => ['http://www.w3.org/ns/anno.jsonld', 'http://iiif.io/api/presentation/3/context.json'] }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('3')
      end
    end

    context 'with edge cases' do
      it 'defaults to v2 for unknown contexts' do
        manifest = { '@context' => 'http://example.com/custom/context.json' }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('2')
      end

      it 'defaults to v2 when context is nil' do
        manifest = { '@context' => nil }
        expect(ScManifest.detect_manifest_version(manifest)).to eq('2')
      end

      it 'defaults to v2 when manifest_hash is nil' do
        expect(ScManifest.detect_manifest_version(nil)).to eq('2')
      end
    end
  end

  describe '.manifest_for_v3_hash' do
    let(:v3_manifest) do
      {
        '@context' => 'http://iiif.io/api/presentation/3/context.json',
        'id' => 'https://example.com/manifest/v3',
        'type' => 'Manifest',
        'label' => { 'en' => ['Test V3 Manifest'] },
        'metadata' => []
      }
    end

    let(:v2_manifest) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => 'https://example.com/manifest/v2',
        '@type' => 'sc:Manifest',
        'label' => 'Test V2 Manifest'
      }
    end

    context 'with v3 manifest' do
      it 'creates ScManifest object successfully' do
        sc_manifest = ScManifest.manifest_for_v3_hash(v3_manifest)
        expect(sc_manifest).to be_a(ScManifest)
        expect(sc_manifest.version).to eq('3')
        expect(sc_manifest.at_id).to eq('https://example.com/manifest/v3')
        expect(sc_manifest.label).to eq('Test V3 Manifest')
      end

      it 'accepts JSON string' do
        sc_manifest = ScManifest.manifest_for_v3_hash(v3_manifest.to_json)
        expect(sc_manifest).to be_a(ScManifest)
        expect(sc_manifest.version).to eq('3')
      end
    end

    context 'with v2 manifest passed as v3' do
      it 'raises VersionMismatchError' do
        expect {
          ScManifest.manifest_for_v3_hash(v2_manifest)
        }.to raise_error(ScManifest::VersionMismatchError, /Expected v3 manifest but detected v2/)
      end

      it 'raises VersionMismatchError for JSON string' do
        expect {
          ScManifest.manifest_for_v3_hash(v2_manifest.to_json)
        }.to raise_error(ScManifest::VersionMismatchError, /Expected v3 manifest but detected v2/)
      end
    end
  end

  describe '.manifest_for_at_id' do
    let(:v2_manifest_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => 'https://example.com/manifest/v2',
        '@type' => 'sc:Manifest',
        'label' => 'Test V2 Manifest',
        'sequences' => []
      }.to_json
    end

    let(:v2_collection_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => 'https://example.com/collection/v2',
        '@type' => 'sc:Collection',
        'label' => 'Test V2 Collection'
      }.to_json
    end

    it 'creates ScManifest object for v2 manifest' do
      allow(URI).to receive(:open).and_return(double(read: v2_manifest_json))

      sc_manifest = ScManifest.manifest_for_at_id('https://example.com/manifest/v2')
      expect(sc_manifest).to be_a(ScManifest)
      expect(sc_manifest.at_id).to eq('https://example.com/manifest/v2')
      expect(sc_manifest.label).to eq('Test V2 Manifest')
    end

    it 'raises ArgumentError for collections' do
      allow(URI).to receive(:open).and_return(double(read: v2_collection_json))

      expect {
        ScManifest.manifest_for_at_id('https://example.com/collection/v2')
      }.to raise_error(ArgumentError, /contains a collection, not an item/)
    end

    it 'trims whitespace from at_id before fetching and assigning it' do
      expect(URI).to receive(:open).with('https://example.com/manifest/v2').and_return(double(read: v2_manifest_json))

      sc_manifest = ScManifest.manifest_for_at_id('  https://example.com/manifest/v2 ')

      expect(sc_manifest.at_id).to eq('https://example.com/manifest/v2')
    end
  end
end
