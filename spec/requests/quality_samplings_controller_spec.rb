require 'spec_helper'

RSpec.describe QualitySamplingsController do
  let(:owner) { create(:unique_user, :owner) }
  let(:user) { create(:unique_user) }
  let(:collection) { create(:collection, :review_required, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work, status: :needs_review, last_editor_user_id: user.id) }

  describe '#index' do
    it 'redirects anonymous users to sign in' do
      get collection_quality_samplings_path(owner, collection)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects unauthorized users to sign in' do
      login_as user

      get collection_quality_samplings_path(owner, collection)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects to the existing sampling for authorized users' do
      login_as owner
      quality_sampling = create(:quality_sampling, user: owner, collection: collection, sample_set: [page.id])

      get collection_quality_samplings_path(owner, collection)

      expect(response).to redirect_to(collection_quality_sampling_path(owner, collection, quality_sampling))
    end
  end

  describe '#initialize_sample' do
    it 'creates a sample for authorized users' do
      login_as owner

      expect do
        post collection_initialize_sample_path(owner, collection)
      end.to change(QualitySampling, :count).by(1)

      expect(response).to redirect_to(collection_sampling_review_flow_path(owner, collection, QualitySampling.last))
    end
  end

  describe '#review' do
    it 'redirects to the next unsampled page' do
      login_as owner
      quality_sampling = create(:quality_sampling, user: owner, collection: collection, sample_set: [page.id])

      get collection_sampling_review_flow_path(owner, collection, quality_sampling)

      expect(response).to redirect_to(collection_sampling_review_page_path(owner, collection, quality_sampling, page, flow: 'quality-sampling'))
    end
  end

  describe '#show' do
    it 'renders the sampling dashboard' do
      login_as owner
      quality_sampling = create(:quality_sampling, user: owner, collection: collection, sample_set: [page.id])

      get collection_quality_sampling_path(owner, collection, quality_sampling)

      expect(response).to have_http_status(:ok)
    end
  end
end
