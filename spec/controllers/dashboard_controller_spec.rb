require 'spec_helper'

RSpec.describe DashboardController, type: :controller do
  describe '#collaborator_time_export' do
    let!(:owner) { build(:owner).tap { |o| o.save(validate: false) } }
    let!(:other_owner) { build(:owner).tap { |o| o.save(validate: false) } }
    let!(:collection_one) { create(:collection, owner_user_id: owner.id) }
    let!(:collection_two) { create(:collection, owner_user_id: owner.id) }
    let!(:other_collection) { create(:collection, owner_user_id: other_owner.id) }
    let!(:user_one) do
      build(:user, login: 'delta-user', display_name: 'Delta User', email: 'delta@example.com').tap { |u| u.save(validate: false) }
    end
    let!(:user_two) do
      build(:user, login: 'epsilon-user', display_name: 'Epsilon User', email: 'epsilon@example.com').tap { |u| u.save(validate: false) }
    end

    before do
      routes.draw { get 'collaborator_time_export' => 'dashboard#collaborator_time_export' }

      allow(controller).to receive(:authorized?).and_return(true)
      allow(controller).to receive(:get_data).and_return(true)
      allow(controller).to receive(:remove_col_id).and_return(true)
      allow(controller).to receive(:current_user).and_return(owner)

      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: collection_one.id, date: Date.new(2026, 1, 1), activity: 'transcribe', minutes: 10)
      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: collection_two.id, date: Date.new(2026, 1, 2), activity: 'translate', minutes: 20)
      create(:ahoy_activity_summary, user_id: user_two.id, collection_id: collection_one.id, date: Date.new(2026, 1, 1), activity: 'transcribe', minutes: 5)
      create(:ahoy_activity_summary, user_id: user_two.id, collection_id: collection_two.id, date: Date.new(2026, 1, 3), activity: 'translate', minutes: 30)
      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: other_collection.id, date: Date.new(2026, 1, 2), activity: 'review', minutes: 999)
    end

    after do
      Rails.application.reload_routes!
    end

    it 'returns collaborator time csv with expected filename and rows' do
      get :collaborator_time_export, params: { start_date: '2026-01-01', end_date: '2026-01-03' }

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Disposition']).to include('filename="2026-01Jan-01-2026-01Jan-03_activity_summary.csv"')

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq(['Username', 'Email', 'Jan 01, 2026', 'Jan 02, 2026', 'Jan 03, 2026'])
      expect(csv.map { |row| row['Username'] }).to eq([user_one.display_name, user_two.display_name])
      expect(csv[0].fields).to eq([user_one.display_name, 'delta@example.com', '10', '20', '0'])
      expect(csv[1].fields).to eq([user_two.display_name, 'epsilon@example.com', '5', '0', '30'])
    end
  end
end
