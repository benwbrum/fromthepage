require 'spec_helper'

describe Admin::Ai::DashboardController do
  let(:user) { create(:unique_user) }
  let(:admin) { create(:unique_user, :admin) }
  let(:page) { create(:page) }

  describe '#index' do
    it 'redirects anonymous and non-admin users' do
      get admin_ai_path
      expect(response).to redirect_to(dashboard_path)

      login_as user
      get admin_ai_path
      expect(response).to redirect_to(dashboard_path)
    end

    it 'defaults to the current calendar month in Time.zone' do
      travel_to Time.zone.local(2026, 8, 18, 12) do
        login_as admin
        get admin_ai_path

        expect(response).to have_http_status(:ok)
        expect(assigns(:start_time)).to eq(Time.zone.local(2026, 8, 1))
        expect(assigns(:end_time)).to eq(Time.zone.local(2026, 9, 1))
      end
    end

    it 'uses inclusive custom date boundaries and excludes records outside them' do
      included = create(:ai_transcription, page: page, created_at: Time.zone.local(2026, 7, 12, 23, 59))
      create(:ai_transcription, page: page, created_at: Time.zone.local(2026, 7, 13))
      create(:ai_transcription, page: page, created_at: Time.zone.local(2026, 7, 9, 23, 59))
      login_as admin

      get admin_ai_path, params: { start_date: '2026-07-10', end_date: '2026-07-12' }

      expect(assigns(:start_time)).to eq(Time.zone.local(2026, 7, 10))
      expect(assigns(:end_time)).to eq(Time.zone.local(2026, 7, 13))
      expect(assigns(:totals)[:total]).to eq(1)
      expect(response.body).to include(included.model)
    end

    it 'validates malformed, reversed, and oversized ranges' do
      login_as admin

      get admin_ai_path, params: { start_date: 'not-a-date', end_date: '2026-07-12' }
      expect(response.body).to include(I18n.t('admin.ai.dashboard.errors.invalid_date'))

      get admin_ai_path, params: { start_date: '2026-07-13', end_date: '2026-07-12' }
      expect(response.body).to include(I18n.t('admin.ai.dashboard.errors.reversed_range'))

      get admin_ai_path, params: { start_date: '2025-01-01', end_date: '2026-01-02' }
      expect(response.body).to include(I18n.t('admin.ai.dashboard.errors.range_too_large', count: 366))
    end

    it 'groups models and statuses, zero fills cells, and calculates totals' do
      time = Time.zone.local(2026, 7, 10, 12)
      create_list(:ai_transcription, 2, page: page, model: 'model-a', status: :finished, created_at: time)
      create(:ai_transcription, page: page, model: 'model-a', status: :error, created_at: time)
      create(:ai_transcription, page: page, model: 'model-b', status: :processing, created_at: time)
      login_as admin

      get admin_ai_path, params: { start_date: '2026-07-10', end_date: '2026-07-10' }

      model_a = assigns(:rows).find { |row| row[:model] == 'model-a' }
      model_b = assigns(:rows).find { |row| row[:model] == 'model-b' }
      expect(model_a).to include(total: 3, success_rate: 66.7)
      expect(model_a[:counts]).to eq('new' => 0, 'processing' => 0, 'finished' => 2, 'error' => 1)
      expect(model_b[:counts]['finished']).to eq(0)
      expect(assigns(:totals)).to eq(
        counts: { 'new' => 0, 'processing' => 1, 'finished' => 2, 'error' => 1 },
        total: 4,
        success_rate: 50.0
      )
    end

    it 'renders the dashboard as the first navigation entry' do
      login_as admin
      get admin_ai_path

      expect(response).to render_template(:index)
      expect(response.body).to include(I18n.t('admin.ai.nav.dashboard'))
      expect(response.body.index(I18n.t('admin.ai.nav.dashboard')))
        .to be < response.body.index(I18n.t('admin.ai.nav.suspicious_behaviors'))
    end
  end
end
