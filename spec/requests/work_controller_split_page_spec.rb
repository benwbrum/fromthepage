require 'spec_helper'

describe WorkController do
  describe '#split_page' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: 'text_and_metadata') }
    let(:work) { create(:work, collection: collection, owner_user_id: owner.id, restrict_scribes: false) }
    let!(:first_page) { create(:page, work: work, position: 1, title: 'Letter one') }
    let!(:second_page) { create(:page, work: work, position: 2) }
    let!(:metadata_field) { create(:transcription_field, :as_metadata, collection: collection) }

    let(:perform_split) do
      post split_page_collection_work_path(owner, collection, work),
        params: { page_id: second_page.id, new_work_title: 'Letter one' }
    end

    context 'when logged in as the owner' do
      before { login_as(owner, scope: :user) }

      it 'always renders the inline success view, never a redirect' do
        perform_split

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:split_page)
      end

      it 'links to the work overview when edit_metadata_after_split is not set' do
        perform_split

        new_work = collection.works.find_by!(title: 'Letter one')
        expect(response.body).to include(%(href="#{collection_read_work_path(owner, collection, new_work)}"))
        expect(response.body).not_to include(%(href="#{describe_collection_work_path(owner, collection, new_work)}"))
      end

      context 'when the work has edit_metadata_after_split enabled and metadata is configured' do
        before { work.update!(edit_metadata_after_split: true) }

        it 'links to the new work metadata form instead of the work overview' do
          perform_split

          new_work = collection.works.find_by!(title: 'Letter one')
          expect(response.body).to include(%(href="#{describe_collection_work_path(owner, collection, new_work)}"))
          expect(response.body).not_to include(%(href="#{collection_read_work_path(owner, collection, new_work)}"))
        end
      end

      context 'when the work has edit_metadata_after_split enabled but the collection has no metadata fields configured' do
        before do
          work.update!(edit_metadata_after_split: true)
          collection.metadata_fields.destroy_all
        end

        it 'falls back to linking to the work overview' do
          perform_split

          new_work = collection.works.find_by!(title: 'Letter one')
          expect(response.body).to include(%(href="#{collection_read_work_path(owner, collection, new_work)}"))
          expect(response.body).not_to include(%(href="#{describe_collection_work_path(owner, collection, new_work)}"))
        end
      end
    end

    context 'when logged in as a non-owner scribe' do
      let(:scribe) { create(:unique_user) }

      before do
        work.update!(edit_metadata_after_split: true)
        login_as(scribe, scope: :user)
      end

      it 'links to the new work metadata form, the same as the owner' do
        perform_split

        new_work = collection.works.find_by!(title: 'Letter one')
        expect(response.body).to include(%(href="#{describe_collection_work_path(owner, collection, new_work)}"))
        expect(response.body).not_to include(%(href="#{collection_read_work_path(owner, collection, new_work)}"))
      end
    end
  end
end
