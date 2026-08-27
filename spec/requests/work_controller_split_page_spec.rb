require 'spec_helper'

describe WorkController do
  describe '#split_page' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: 'text_and_metadata', allow_transcriber_segmentation: true) }
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

      it 'records the work the new work was split from' do
        perform_split

        new_work = collection.works.find_by!(title: 'Letter one')
        expect(new_work.split_from_work).to eq(work)
      end

      it 'refuses the split when segmentation is not enabled for the work' do
        collection.update!(allow_transcriber_segmentation: false)

        expect { perform_split }.not_to change(Work, :count)
        expect(response).to redirect_to(dashboard_path)
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

  describe '#describe navigation for a work split off another work' do
    let(:owner) { create(:unique_user, :owner) }
    let(:collection) { create(:collection, owner_user_id: owner.id, works: [], data_entry_type: 'text_and_metadata') }
    let(:original_work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let(:new_work) { create(:work, collection: collection, owner_user_id: owner.id, split_from_work: original_work) }
    let!(:original_first_page) { create(:page, work: original_work, position: 1) }
    let!(:new_work_page) { create(:page, work: new_work, position: 1) }
    let!(:metadata_field) { create(:transcription_field, :as_metadata, collection: collection) }

    before { login_as(owner, scope: :user) }

    it 'points the "next" arrow back to the first page of the original work' do
      get describe_collection_work_path(owner, collection, new_work)

      expect(response).to have_http_status(:ok)
      back_link = Nokogiri::HTML(response.body).at_css('a.page-nav_next')
      expect(back_link).to be_present
      expect(back_link['href']).to eq(
        collection_transcribe_page_path(owner, collection, original_work, original_first_page.id)
      )
    end
  end
end
