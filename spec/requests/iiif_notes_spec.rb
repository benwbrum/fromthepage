require 'spec_helper'

describe 'IIIF Notes API' do
  let(:owner) { User.find_by(owner: true) || create(:user, owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  before do
    Current.user = owner
  end

  describe 'GET /iiif/:page_id/note/:note_id' do
    context 'when the note exists' do
      let!(:note) do
        create(:note,
               collection_id: collection.id,
               work_id: work.id,
               page_id: page.id,
               user_id: owner.id,
               body: 'Test note body')
      end

      it 'returns 200 with the note as JSON' do
        get "/iiif/#{page.id}/note/1"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['resource']['chars']).to eq('Test note body')
      end
    end

    context 'when the note does not exist (out of range index)' do
      it 'returns 404 when page has no notes' do
        get "/iiif/#{page.id}/note/1"

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when note_id is beyond the number of notes' do
        create(:note,
               collection_id: collection.id,
               work_id: work.id,
               page_id: page.id,
               user_id: owner.id)

        get "/iiif/#{page.id}/note/99"

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 when note_id is zero' do
        get "/iiif/#{page.id}/note/0"

        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /iiif/:page_id/notes' do
    context 'when the page has notes' do
      let!(:note) do
        create(:note,
               collection_id: collection.id,
               work_id: work.id,
               page_id: page.id,
               user_id: owner.id,
               body: 'Test note body')
      end

      it 'returns 200 with an annotation list' do
        get "/iiif/#{page.id}/notes"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['resources']).to be_present
      end
    end

    context 'when the page has no notes' do
      it 'returns 200 with an empty annotation list' do
        get "/iiif/#{page.id}/notes"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['resources']).to be_blank
      end
    end
  end
end
