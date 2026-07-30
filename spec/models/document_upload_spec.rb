require 'spec_helper'

describe DocumentUpload do
  let(:owner) { User.find_by(login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }

  describe 'validations' do
    let(:attachment) { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }

    subject { build(:document_upload, collection: collection, attachment: attachment) }

    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'missing file' do
      let(:attachment) { nil }

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:attachment]).to include("can't be blank")
      end
    end

    context 'invalid file type' do
      let(:attachment) do
        Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/invalid_file_type.txt')))
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:attachment]).to include(
          'You are not allowed to upload "TXT" files, allowed types: PDF, ZIP'
        )
      end
    end
  end

  describe '#log_contents' do
    let(:document_upload) { create(:document_upload, collection: collection, user: owner) }

    after do
      File.delete(document_upload.log_file) if File.exist?(document_upload.log_file)
    end

    it 'reads the upload log file when present' do
      FileUtils.mkdir_p(File.dirname(document_upload.log_file))
      File.write(document_upload.log_file, 'upload log contents')

      expect(document_upload.log_contents).to eq('upload log contents')
    end

    it 'returns a cleaned message when the upload log file is missing' do
      expect(document_upload.log_contents).to eq('Log file has been cleaned')
    end
  end
end
