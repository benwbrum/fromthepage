require 'spec_helper'

describe Metadata::RefreshJob do
  include ActiveJob::TestHelper

  let(:owner) { create(:unique_user, :owner) }
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

  let(:document_set) do
    create(:document_set, collection_id: collection.id, owner_user_id: owner.id, works: [work, work_no_manifest])
  end

  subject(:worker) { described_class.new }

  let(:perform_worker) do
    worker.perform(id: collection.id, type: 'collection')
  end

  context 'collection' do
    it 'refreshes metadata' do
      expect(work.original_metadata).to be_nil

      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        perform_enqueued_jobs do
          perform_worker
        end
      end

      expect(work.reload.original_metadata).to eq(original_metadata)
    end

    context 'with graceful errors' do
      context 'missing collection id' do
        let(:perform_worker) do
          worker.perform(id: 'wrong collection id', type: 'collection')
        end

        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end

      context 'bad request' do
        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end
    end
  end

  context 'document_set' do
    let(:perform_worker) do
      worker.perform(id: document_set.id, type: 'document_set')
    end

    it 'refreshes metadata' do
      expect(work.original_metadata).to be_nil

      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        perform_enqueued_jobs do
          perform_worker
        end
      end

      expect(work.reload.original_metadata).to eq(original_metadata)
    end

    context 'with graceful errors' do
      context 'missing document set id' do
        let(:perform_worker) do
          worker.perform(id: 'wrong document set id', type: 'document_set')
        end

        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end

      context 'bad request' do
        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end
    end
  end

  context 'work' do
    let(:perform_worker) do
      worker.perform(id: work.id, type: 'work')
    end

    it 'refreshes metadata' do
      expect(work.original_metadata).to be_nil

      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        perform_enqueued_jobs do
          perform_worker
        end
      end

      expect(work.reload.original_metadata).to eq(original_metadata)
    end

    context 'with graceful errors' do
      context 'missing work id' do
        let(:perform_worker) do
          worker.perform(id: 'wrong work id', type: 'work')
        end

        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end

      context 'bad request' do
        it 'error is handled' do
          expect {
            VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
              perform_enqueued_jobs do
                perform_worker
              end
            end
          }.not_to raise_error
        end
      end
    end
  end

  context 'bad type' do
    let(:perform_worker) do
      worker.perform(id: collection.id, type: 'user')
    end

    it 'error is handled' do
      expect {
        VCR.use_cassette('iiif/refresh_metadata_failed', record: :none) do
          perform_enqueued_jobs do
            perform_worker
          end
        end
      }.not_to raise_error
    end
  end

  context 'SMTP disabled' do
    before { stub_const('SMTP_ENABLED', false) }

    it 'refreshes metadata' do
      expect(work.original_metadata).to be_nil

      VCR.use_cassette('iiif/refresh_metadata', record: :none) do
        perform_enqueued_jobs do
          perform_worker
        end
      end

      expect(work.reload.original_metadata).to eq(original_metadata)
    end
  end
end
