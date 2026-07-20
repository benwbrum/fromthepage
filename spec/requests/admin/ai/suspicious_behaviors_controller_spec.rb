require 'spec_helper'

describe Admin::Ai::SuspiciousBehaviorsController do
  let!(:user) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work) }
  let!(:suspicious_behavior) { create(:suspicious_behavior, collection: collection, page: page, user: user, resolved_by_user_id: nil) }

  describe '#index' do
    let(:action_path) { admin_ai_suspicious_behaviors_path }
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
          behavior_type: 'large_paste',
          ordering: 'ASC',
          sorting: 'created_at',
          search_user: user.slug,
          search_collection: collection.slug,
          search_owner: owner.slug
        }
      end
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as admin
        subject
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
      end

      context 'when elastic enabled' do
        before do
          VCR.configure { |c| c.allow_http_connections_when_no_cassette = true }

          stub_const('ELASTIC_ENABLED', true)
        end

        after do
          VCR.configure { |c| c.allow_http_connections_when_no_cassette = false }
        end

        it 'renders status and template' do
          login_as admin
          subject
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end
    end
  end

  describe '#show' do
    let(:action_path) { admin_ai_suspicious_behavior_path(suspicious_behavior) }
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
