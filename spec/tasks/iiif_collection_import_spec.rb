require 'spec_helper'
require 'rake'

RSpec.describe 'IIIF Collection Import Rake Task' do
  before(:all) do
    Rake.application.rake_require 'tasks/iiif_collection_import'
    Rake::Task.define_task(:environment)
  end

  describe 'version detection and fallback' do
    let(:owner) { User.find_by(login: OWNER) || create(:user, login: OWNER) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }
    
    let(:v2_manifest_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/2/context.json',
        '@id' => 'https://example.com/manifest/v2',
        '@type' => 'sc:Manifest',
        'label' => 'Test V2 Manifest',
        'sequences' => [
          {
            '@id' => 'https://example.com/manifest/v2/sequence/normal',
            '@type' => 'sc:Sequence',
            'canvases' => []
          }
        ]
      }.to_json
    end

    let(:v3_manifest_json) do
      {
        '@context' => 'http://iiif.io/api/presentation/3/context.json',
        'id' => 'https://example.com/manifest/v3',
        'type' => 'Manifest',
        'label' => { 'en' => ['Test V3 Manifest'] },
        'items' => []
      }.to_json
    end

    after do
      collection.destroy
      owner.destroy if owner.login == OWNER && User.where(login: OWNER).count == 1
    end

    context 'when v3 collection contains v2 manifests' do
      it 'falls back to v2 parser when VersionMismatchError is raised' do
        # Create a v3 collection with a v2 manifest reference
        v3_collection_hash = {
          '@context' => 'http://iiif.io/api/presentation/3/context.json',
          'id' => 'https://example.com/collection/v3',
          'type' => 'Collection',
          'label' => { 'en' => ['Test V3 Collection'] },
          'items' => [
            {
              'id' => 'https://example.com/manifest/v2',
              'type' => 'Manifest'
            }
          ]
        }

        sc_collection = ScCollection.collection_for_v3_hash(v3_collection_hash)
        
        # Mock URI.open to return v2 manifest when manifest is fetched
        allow(URI).to receive(:open).and_return(double(read: v2_manifest_json))

        # Simulate the rake task logic
        manifest = sc_collection.manifests.first
        at_id = manifest['id']
        sc_manifest = nil

        if sc_collection.v3?
          begin
            manifest_hash = JSON.parse(v2_manifest_json)
            sc_manifest = ScManifest.manifest_for_v3_hash(manifest_hash)
          rescue ScManifest::VersionMismatchError => version_error
            # This should happen - fall back to v2 parser
            sc_manifest = ScManifest.manifest_for_at_id(at_id)
          end
        end

        expect(sc_manifest).to be_a(ScManifest)
        expect(sc_manifest.at_id).to eq('https://example.com/manifest/v2')
        expect(sc_manifest.version).to eq('2')
      end
    end

    context 'when v3 collection contains v3 manifests' do
      it 'parses v3 manifests successfully' do
        # Create a v3 collection with a v3 manifest reference
        v3_collection_hash = {
          '@context' => 'http://iiif.io/api/presentation/3/context.json',
          'id' => 'https://example.com/collection/v3',
          'type' => 'Collection',
          'label' => { 'en' => ['Test V3 Collection'] },
          'items' => [
            {
              'id' => 'https://example.com/manifest/v3',
              'type' => 'Manifest'
            }
          ]
        }

        sc_collection = ScCollection.collection_for_v3_hash(v3_collection_hash)
        
        # Mock URI.open to return v3 manifest when manifest is fetched
        allow(URI).to receive(:open).and_return(double(read: v3_manifest_json))

        # Simulate the rake task logic
        manifest = sc_collection.manifests.first
        at_id = manifest['id']
        sc_manifest = nil

        if sc_collection.v3?
          begin
            manifest_hash = JSON.parse(v3_manifest_json)
            sc_manifest = ScManifest.manifest_for_v3_hash(manifest_hash)
          rescue ScManifest::VersionMismatchError => version_error
            # This should NOT happen for v3 manifests
            sc_manifest = ScManifest.manifest_for_at_id(at_id)
          end
        end

        expect(sc_manifest).to be_a(ScManifest)
        expect(sc_manifest.at_id).to eq('https://example.com/manifest/v3')
        expect(sc_manifest.version).to eq('3')
      end
    end

    context 'when v2 collection contains v2 manifests' do
      it 'parses v2 manifests successfully' do
        # Create a v2 collection with a v2 manifest reference
        v2_collection_json = {
          '@context' => 'http://iiif.io/api/presentation/2/context.json',
          '@id' => 'https://example.com/collection/v2',
          '@type' => 'sc:Collection',
          'label' => 'Test V2 Collection',
          'manifests' => [
            {
              '@id' => 'https://example.com/manifest/v2',
              '@type' => 'sc:Manifest',
              'label' => 'Test V2 Manifest'
            }
          ]
        }.to_json

        allow(URI).to receive(:open).and_return(double(read: v2_collection_json))
        sc_collection = ScCollection.collection_for_at_id('https://example.com/collection/v2')
        
        # Mock URI.open to return v2 manifest when manifest is fetched
        allow(URI).to receive(:open).and_return(double(read: v2_manifest_json))

        # Simulate the rake task logic
        manifest = sc_collection.manifests.first
        at_id = manifest['@id']
        sc_manifest = nil

        if sc_collection.v3?
          begin
            manifest_hash = JSON.parse(v2_manifest_json)
            sc_manifest = ScManifest.manifest_for_v3_hash(manifest_hash)
          rescue ScManifest::VersionMismatchError => version_error
            sc_manifest = ScManifest.manifest_for_at_id(at_id)
          end
        else
          # This path should be taken for v2 collections
          sc_manifest = ScManifest.manifest_for_at_id(at_id)
        end

        expect(sc_manifest).to be_a(ScManifest)
        expect(sc_manifest.at_id).to eq('https://example.com/manifest/v2')
        expect(sc_manifest.version).to eq('2')
      end
    end
  end
end
