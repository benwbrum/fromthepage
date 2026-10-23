require 'spec_helper'

describe BulkExport do
  let(:collection) { create(:collection) }
  let(:user) { create(:user) }

  describe '#downloadable?' do
    context 'when output is attached via Active Storage' do
      let(:bulk_export) { create(:bulk_export, :finished, collection_id: collection.id, user_id: user.id) }

      before do
        bulk_export.output.attach(
          io: StringIO.new('fake zip content'),
          filename: 'export.zip',
          content_type: 'application/zip'
        )
      end

      it 'returns true' do
        expect(bulk_export.downloadable?).to be true
      end
    end

    context 'when legacy zip file exists on disk' do
      let(:bulk_export) { create(:bulk_export, :finished, collection_id: collection.id, user_id: user.id) }

      before do
        FileUtils.mkdir_p(bulk_export.zip_file_path)
        FileUtils.touch(bulk_export.zip_file_name)
      end

      after do
        File.delete(bulk_export.zip_file_name) if File.exist?(bulk_export.zip_file_name)
      end

      it 'returns true' do
        expect(bulk_export.downloadable?).to be true
      end
    end

    context 'when neither Active Storage attachment nor legacy zip file exists' do
      let(:bulk_export) { create(:bulk_export, :finished, collection_id: collection.id, user_id: user.id) }

      it 'returns false' do
        expect(bulk_export.downloadable?).to be false
      end
    end

    context 'when export has been cleaned' do
      let(:bulk_export) { create(:bulk_export, :cleaned, collection_id: collection.id, user_id: user.id) }

      it 'returns false' do
        expect(bulk_export.downloadable?).to be false
      end
    end
  end
end
