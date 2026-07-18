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

    it 'redirects admin to new AI suspicious behaviors path' do
      login_as admin
      subject
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(admin_ai_suspicious_behaviors_path)
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

    it 'redirects admin to new AI suspicious behavior path' do
      login_as admin
      subject
      expect(response).to have_http_status(:moved_permanently)
      expect(response).to redirect_to(admin_ai_suspicious_behavior_path(suspicious_behavior))
    end
  end
end
