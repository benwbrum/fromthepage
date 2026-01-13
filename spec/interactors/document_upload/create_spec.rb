require 'spec_helper'

describe DocumentUpload::Create do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:attachment_blob) do
    fixture_file_upload(Rails.root.join('test_data/uploads/test.pdf'), 'application/pdf')
  end
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: attachment_blob, filename: 'test.pdf',
      content_type: 'application/pdf')
  end
  let(:signed_id) { blob.signed_id }

  let(:document_upload_params) do
    {
      attachment: signed_id,
      collection_id: collection.id,
      ocr: true,
      preserve_titles: true
    }
  end

  let(:result) do
    described_class.new(document_upload_params: document_upload_params, user: owner).call
  end

  it 'creates document upload' do
    expect(result.success?).to be_truthy
    expect(result.document_upload).to have_attributes(
      ocr: true,
      preserve_titles: true,
      collection_id: collection.id
    )
  end

  context 'when missing signed id' do
    let(:document_upload_params) do
      {
        attachment: '',
        collection_id: collection.id,
        ocr: true,
        preserve_titles: true
      }
    end

    it 'fails to creates document upload' do
      expect(result.success?).to be_falsey
      expect(result.document_upload.errors.full_messages).to include("File can't be blank")
    end
  end

  context 'when unsupported file type' do
    let(:attachment_blob) do
      fixture_file_upload(Rails.root.join('test_data/images/pages/sanskrit.jpg'), 'image/jpeg')
    end
    let(:blob) do
      ActiveStorage::Blob.create_and_upload!(io: attachment_blob, filename: 'sanskrit.jpg',
        content_type: 'image/jpeg')
    end

    let(:document_upload_params) do
      {
        attachment: signed_id,
        collection_id: collection.id,
        ocr: true,
        preserve_titles: true
      }
    end

    it 'fails to creates document upload' do
      expect(result.success?).to be_falsey
      expect(result.document_upload.errors.full_messages).to include("File You are not allowed to upload \"JPG\" files, allowed types: PDF, ZIP")
    end
  end
end
