require 'spec_helper'

describe Elasticsearch::Collection::SyncJob do
  include ActiveJob::TestHelper

  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work) }
  let(:records) { [user, collection, work, page] }

  subject(:worker) { described_class.new }

  before do
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

    stub_const('ELASTIC_ENABLED', true)
  end

  after do
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

    stub_const('ELASTIC_ENABLED', true)

    records.reverse.each(&:destroy!)

    VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
  end

  context 'when collection' do
    let(:collection_id) { collection.id }
    let(:type) { :collection }
    let(:skip_collection) { false }

    let(:perform_worker) do
      worker.perform(user_id: nil, collection_id: collection_id, type: type,
        skip_collection: skip_collection)
    end

    it 'syncs es records' do
      perform_enqueued_jobs do
        perform_worker
      end
    end

    context 'when skip collection' do
      let(:skip_collection) { true }
      it 'syncs es records' do
        perform_enqueued_jobs do
          perform_worker
        end
      end
    end
  end

  context 'when document_set' do
    let!(:document_set) { create(:document_set, collection_id: collection.id, owner_user_id: user.id, works: [work]) }

    let(:collection_id) { document_set.id }
    let(:type) { :document_set }
    let(:skip_collection) { false }

    let(:perform_worker) do
      worker.perform(user_id: nil, collection_id: collection_id, type: type,
        skip_collection: skip_collection)
    end

    it 'syncs es records' do
      perform_enqueued_jobs do
        perform_worker
      end
    end

    context 'when skip collection' do
      let(:skip_collection) { true }
      it 'syncs es records' do
        perform_enqueued_jobs do
          perform_worker
        end
      end
    end
  end
end
