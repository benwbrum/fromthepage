require 'spec_helper'

describe UserController do
  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(owner: true) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  describe '#search' do
    let(:action_path) { owner_search_path(owner) }
    let(:params) { { term: page.title } }

    let(:subject) { get action_path, params: params }

    before do
      stub_const('ELASTIC_ENABLED', true)

      CollectionsIndex.import collection.reload
      WorksIndex.import collection.works
      PagesIndex.import collection.works.flat_map(&:pages)
    end

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search)
    end
  end
end
