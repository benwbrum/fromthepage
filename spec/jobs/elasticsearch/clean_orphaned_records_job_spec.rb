require 'spec_helper'

describe Elasticsearch::CleanOrphanedRecordsJob do
  include ActiveJob::TestHelper

  let(:identifier) { 'pneumonoultramicroscopicsilicovolcanoconiosis' }

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, title: identifier) }

  subject(:worker) { described_class.new }

  before(:each) do
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

    stub_const('ELASTIC_ENABLED', true)

    collection.save!
  end

  after(:each) do
    VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

    stub_const('ELASTIC_ENABLED', true)

    collection.destroy!

    VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
  end

  it 'deletes orphaned records' do
    expect(Collection.es_search(query: identifier).pluck('_id')).to include(collection.id.to_s)
    owner.delete

    perform_enqueued_jobs do
      worker.perform
    end

    Chewy.client.indices.refresh(index: '_all')
    expect(Collection.es_search(query: identifier).pluck('_id')).not_to include(collection.id.to_s)
  end
end
