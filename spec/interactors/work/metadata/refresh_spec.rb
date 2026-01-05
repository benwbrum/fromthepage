require 'spec_helper'

describe Work::Metadata::Refresh do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:original_metadata) { [{ label: 'en', value: ['Original Metadata'] }].to_json }
  let(:at_id) { 'http://example.com/manifest' }
  let(:v3_hash) do
    {
      "@context" => "http://iiif.io/api/presentation/3/context.json",
            "id" => "http://example.com/manifest",
          "type" => "Manifest",
         "label" => {
          "en" => [
            "Original Metadata"
          ]
      },
      "metadata" => [
          {
            "label" => {
              "en" => [
                 "Origin"
               ]
             },
             "value" => {
               "en" => [
                  "Test Data"
               ]
             }
          }
      ],
       "items" => []
    }.to_json.to_s
  end

  let(:sc_manifest) { ScManifest.manifest_for_v3_hash(v3_hash) }
  let(:work) { create(:work, collection: collection, sc_manifest: sc_manifest) }
  let(:work_no_manifest) { create(:work, collection: collection) }

  let(:result) do
    described_class.new(work_ids: [work.id, work_no_manifest.id]).call
  end

  context 'when original metadata is blank' do
    it 'adds metadata' do
      expect(work.original_metadata).to be_nil
      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        result
      end
      expect(result.success?).to be_truthy
      expect(work.reload.original_metadata).to eq(original_metadata)
    end
  end

  context 'when original metadata is present' do
    let(:existing_metadata) { [{ label: 'en', value: ['Existing Metadata'] }].to_json }
    let(:work) { create(:work, collection: collection, original_metadata: existing_metadata, sc_manifest: sc_manifest) }

    it 'updates metadata' do
      expect(work.original_metadata).to eq(existing_metadata)
      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        result
      end
      expect(result.success?).to be_truthy
      expect(work.reload.original_metadata).to eq(original_metadata)
    end
  end

  context 'when refresh fails' do
    it 'handles error gracefully' do
      expect(work.original_metadata).to be_nil
      VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
        result
      end

      expect(result.success?).to be_falsey
      expect(result.logs).to include(
        "Refreshing metadata for work: #{work.id}",
        "Failed to refresh metadata for #{work.slug}",
        'Error: 404 Not Found'
      )
    end
  end

  context 'when 503 error' do
    it 'handles error gracefully' do
      expect(work.original_metadata).to be_nil
      VCR.use_cassette('iiif/refresh_metadata_unavailable', record: :none, allow_playback_repeats: false) do
        result
      end

      expect(result.success?).to be_falsey
      expect(result.logs).to include(
        "Refreshing metadata for work: #{work.id}",
        "503 Service Unavailable - retrying in 5s (attempt 1/3)",
        "Refreshing metadata for work: #{work.id}",
        "503 Service Unavailable - retrying in 10s (attempt 2/3)",
        "Refreshing metadata for work: #{work.id}",
        "503 Service Unavailable - retrying in 15s (attempt 3/3)",
        "Failed to refresh metadata for #{work.slug}",
        'Error: 503 Service Unavailable'
      )
    end
  end
end
