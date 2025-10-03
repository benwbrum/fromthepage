require 'spec_helper'

describe DashboardController do
  before do
    Current.user = owner
  end

  let!(:owner) { build(:owner).tap { |o| o.save(validate: false) } }
  let!(:user) { build(:user).tap { |u| u.save(validate: false) } }
  let!(:guest) { build(:user, guest: true).tap { |u| u.save(validate: false) } }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  describe '#dashboard_role' do
    let(:action_path) { dashboard_role_path }

    let(:subject) { get action_path }

    context 'when owner' do
      it 'redirects' do
        login_as owner
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_owner_path)
      end
    end

    context 'when guest user' do
      it 'redirects' do
        login_as guest
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(guest_dashboard_path)
      end
    end

    context 'when user' do
      it 'redirects' do
        login_as user
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(dashboard_watchlist_path)
      end
    end

    context 'when not logged in' do
      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(guest_dashboard_path)
      end
    end
  end

  describe '#index' do
    let(:action_path) { dashboard_path }

    let(:subject) { get action_path }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(collections_list_path)
    end

    context 'when collection count > 1000' do
      before do
        allow(Collection).to receive_message_chain(:all, :count).and_return(1001)
      end

      it 'redirects' do
        subject

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(landing_page_path)
      end
    end
  end

  describe '#collections_list' do
    let(:action_path) { collections_list_path }

    let(:subject) { get action_path }

    it 'renders status and template' do
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:collections_list)
    end

    context 'when logged in' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:collections_list)
      end
    end
  end

  describe '#startproject' do
    let(:action_path) { dashboard_startproject_path }

    let(:subject) { get action_path }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(dashboard_path)
    end

    context 'when logged in owner' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:startproject)
      end
    end
  end

  describe '#your_hours' do
    let(:action_path) { dashboard_your_hours_path }
    let(:params) { {} }

    let(:subject) { get action_path, params: params }

    it 'redirects' do
      subject

      expect(response).to have_http_status(:redirect)
      expect(response).to redirect_to(landing_page_path)
    end

    context 'when logged' do
      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:your_hours)
      end

      context 'when start_date > end_date' do
        let(:params) { { start_date: '2025-01-01', end_date: '2024-01-01' } }

        it 'redirects' do
          login_as owner
          subject

          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(dashboard_your_hours_path)
        end
      end
    end
  end

  describe '#owner' do
    let(:action_path) { dashboard_owner_path }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:owner)
    end
  end

  describe '#summary' do
    let(:action_path) { dashboard_summary_path }
    let(:params) { {} }

    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:summary)
    end

    context 'with params' do
      let(:params) { { start_date: '2024-01-01', end_date: '2025-01-01' } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:summary)
      end
    end
  end

  describe '#watchlist' do
    let(:action_path) { dashboard_watchlist_path }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as user
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:watchlist)
    end
  end

  describe '#exports' do
    let(:action_path) { dashboard_exports_path }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:exports)
    end
  end

  describe '#guest' do
    let(:action_path) { guest_dashboard_path }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:guest)
    end
  end

  describe '#landing_page' do
    let(:action_path) { landing_page_path }
    let(:params) { {} }

    let(:subject) { get action_path, params: params }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:landing_page)
    end

    context 'with search param' do
      let(:params) { { search: collection.title } }
      let(:subject) { get action_path, params: params, as: :turbo_stream }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:landing_page)
      end
    end

    context 'with elasticsearch' do
      before do
        stub_const('ELASTIC_ENABLED', true)
        CollectionsIndex.import collection
      end

      let(:params) { { search: collection.title } }

      it 'renders status and template' do
        login_as owner
        subject

        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:landing_page)
      end

      context 'filter by collection' do
        let(:params) { { search: collection.title, filter: 'collection' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:landing_page)
        end
      end

      context 'filter by work' do
        let(:params) { { search: collection.title, filter: 'work' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:landing_page)
        end
      end

      context 'filter by page' do
        let(:params) { { search: collection.title, filter: 'page' } }

        it 'renders status and template' do
          login_as owner
          subject

          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:landing_page)
        end
      end
    end
  end

  describe '#browse_tag' do
    let(:intro_block) { '<h1> Intro Block </h1>' }
    let!(:collection) do
      create(:collection, :with_pages, :with_picture, owner_user_id: owner.id, intro_block: intro_block)
    end
    let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
    let!(:document_set) do
      create(:document_set, :public, :with_picture, collection_id: collection.id, owner_user_id: owner.id,
                                                    description: intro_block, works: [work])
    end
    let!(:tag) { create(:tag, collections: [collection]) }
    let(:action_path) { browse_tag_path(ai_text: tag.ai_text) }

    let(:subject) { get action_path }

    it 'renders status and template' do
      login_as owner
      subject

      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:browse_tag)
    end
  end
end
