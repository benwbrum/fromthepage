require 'spec_helper'

describe WorkController do
  describe '#split_page' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id, restrict_scribes: false) }
    let!(:first_page) { create(:page, work: work, position: 1, title: 'Letter one') }
    let!(:second_page) { create(:page, work: work, position: 2) }

    context 'when logged in as the owner' do
      before { login_as(owner, scope: :user) }

      it 'redirects to the new work metadata form when edit_metadata_after_split is set' do
        post split_page_collection_work_path(owner, collection, work),
          params: { page_id: second_page.id, new_work_title: 'Letter one', edit_metadata_after_split: '1' }

        new_work = Work.find_by!(title: 'Letter one')
        expect(response).to redirect_to(edit_metadata_collection_work_path(owner, collection, new_work))
      end

      it 'renders the inline success view when the option is not selected' do
        post split_page_collection_work_path(owner, collection, work),
          params: { page_id: second_page.id, new_work_title: 'Letter one' }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:split_page)
      end
    end

    context 'when logged in as a non-owner scribe' do
      let(:scribe) { create(:unique_user) }

      before { login_as(scribe, scope: :user) }

      it 'ignores the edit_metadata_after_split option' do
        post split_page_collection_work_path(owner, collection, work),
          params: { page_id: second_page.id, new_work_title: 'Letter one', edit_metadata_after_split: '1' }

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:split_page)
      end
    end
  end
end
