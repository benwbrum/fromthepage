require 'spec_helper'

describe DocumentUpload do
  let(:owner) { User.find_by(login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }

  describe 'validations' do
    let(:file) { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }

    subject { build(:document_upload, collection: collection, file: file) }

    it 'is valid' do
      expect(subject).to be_valid
    end

    context 'invalid file type' do
      let(:file) do
        Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/invalid_file_type.txt')))
      end

      it 'is invalid' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:file]).to include(
          "can't be blank",
          'You are not allowed to upload "txt" files, allowed types: zip, pdf'
        )
      end
    end
  end
end
