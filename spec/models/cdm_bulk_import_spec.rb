require 'spec_helper'

RSpec.describe CdmBulkImport, type: :model do
  describe '#collection_or_document_set' do
    let(:user) { create(:user) }

    it 'returns the collection when collection_param is a collection id' do
      collection = create(:collection)
      import = described_class.new(user: user, collection_param: collection.id.to_s)

      expect(import.collection_or_document_set).to eq(collection)
    end

    it 'returns the document set when collection_param has a document set prefix' do
      document_set = create(:document_set)
      import = described_class.new(user: user, collection_param: "D#{document_set.id}")

      expect(import.collection_or_document_set).to eq(document_set)
    end

    it 'returns nil when the target cannot be found' do
      import = described_class.new(user: user, collection_param: '999999')

      expect(import.collection_or_document_set).to be_nil
    end
  end

  describe '#submit_background_task' do
    let(:import) { described_class.create!(user: create(:user), collection_param: create(:collection).id.to_s) }

    before do
      stub_const('RAKE', 'bundle exec rake')
      stub_const('NICE_RAKE_LEVEL', 7)
      allow(import).to receive(:system)
    end

    it 'submits the bulk import rake task in the background' do
      stub_const('NICE_RAKE_ENABLED', false)

      import.submit_background_task

      expect(import).to have_received(:system).with("bundle exec rake fromthepage:bulk_import_cdm[#{import.id}]  --trace  2>&1 &")
    end

    it 'uses nice when nice rake is enabled' do
      stub_const('NICE_RAKE_ENABLED', true)

      import.submit_background_task

      expect(import).to have_received(:system).with("nice -n 7 bundle exec rake fromthepage:bulk_import_cdm[#{import.id}]  --trace  2>&1 &")
    end
  end
end
