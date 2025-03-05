require 'spec_helper'

describe UserController do
  before do
    stub_const('ELASTIC_ENABLED', true)
    User.current_user = owner
  end

  let!(:owner) { build(:owner).tap { |o| o.save(validate: false) } }
  let!(:user) { build(:user).tap { |u| u.save(validate: false) } }
  let!(:guest) { build(:user, guest: true).tap { |u| u.save(validate: false) } }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#search' do
    let(:action_path) { owner_search_path(owner) }
    let(:params) { { term: collection.title } }

    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:search)
    end

    context 'no term' do
      let(:params) { {} }

      it 'renders status and template' do
        stub_const('ELASTIC_ENABLED', true)

        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:search)
      end
    end
  end
end
