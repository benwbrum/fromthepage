require 'spec_helper'

describe Admin::SuspiciousBehaviorsController do
  let!(:user) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:suspicious_behavior) { create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: nil) }

  describe '#index' do
    let(:action_path) { admin_suspicious_behaviors_path }
    let(:params) { {} }
    let(:subject) { get action_path, params: params }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not admin' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders status and template' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'filters' do
      let(:params) do
        {
          behaviour_type: 'large_paste',
          status: 'pending',
          ordering: 'ASC',
          sorting: 'resolved_at'
        }
      end
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as admin
        subject
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end
    end
  end

  describe '#show' do
    let(:action_path) { admin_suspicious_behavior_path(suspicious_behavior) }
    let(:subject) { get action_path }

    it 'redirects when not logged in' do
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'redirects when not admin' do
      login_as user
      subject
      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'renders status' do
      login_as admin
      subject
      expect(response).to have_http_status(:ok)
    end
  end
end
