require 'spec_helper'

describe Work::Metadata::Refresh do
  let(:owner) { User.find_by(login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:original_metadata) { [{ label: 'en', value: ['Original Metadata'] }].to_json }
  let(:at_id) { 'http://example.com/manifest' }
  let(:v3_hash) do
    {
      id: at_id,
      label: { en: ['Original Metadata'] },
      metadata: original_metadata
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
end
