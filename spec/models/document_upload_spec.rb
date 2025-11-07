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

  describe '.search' do
    let!(:user1) { create(:unique_user, login: 'testuser', display_name: 'Test User', email: 'test@example.com') }
    let!(:user2) { create(:unique_user, login: 'otheruser', display_name: 'Other User', email: 'other@example.com') }
    let!(:collection1) { create(:collection, owner_user_id: user1.id) }
    let!(:collection2) { create(:collection, owner_user_id: user2.id) }
    let(:file1) { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }
    let(:file2) { Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, 'test_data/uploads/test.pdf'))) }
    let!(:upload1) { create(:document_upload, collection: collection1, user: user1, file: file1) }
    let!(:upload2) { create(:document_upload, collection: collection2, user: user2, file: file2) }

    it 'finds uploads by user login' do
      results = DocumentUpload.search('testuser')
      expect(results).to include(upload1)
      expect(results).not_to include(upload2)
    end

    it 'finds uploads by user display name' do
      results = DocumentUpload.search('Test User')
      expect(results).to include(upload1)
      expect(results).not_to include(upload2)
    end

    it 'finds uploads by user email' do
      results = DocumentUpload.search('test@example.com')
      expect(results).to include(upload1)
      expect(results).not_to include(upload2)
    end

    it 'is case insensitive' do
      results = DocumentUpload.search('TESTUSER')
      expect(results).to include(upload1)
      expect(results).not_to include(upload2)
    end

    it 'finds partial matches' do
      results = DocumentUpload.search('test')
      expect(results).to include(upload1)
      expect(results).not_to include(upload2)
    end
  end
end
