require 'spec_helper'

describe 'Deleting a field', type: :request do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }

  before { login_as owner }

  it 'returns to the metadata field editor after deleting a metadata field' do
    field = create(:transcription_field, :as_metadata, collection: collection, label: 'Topics', line_number: 1)
    get transcription_field_delete_path(field_id: field.id, collection_id: collection.id)
    expect(response).to redirect_to(collection_edit_metadata_fields_path(owner, collection))
    expect(TranscriptionField.exists?(field.id)).to be(false)
  end

  it 'returns to the transcription field editor after deleting a transcription field' do
    field = create(:transcription_field, collection: collection, label: 'Name', line_number: 1)
    get transcription_field_delete_path(field_id: field.id, collection_id: collection.id)
    expect(response).to redirect_to(collection_edit_fields_path(owner, collection))
    expect(TranscriptionField.exists?(field.id)).to be(false)
  end
end
