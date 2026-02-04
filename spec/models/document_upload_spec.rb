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
end
