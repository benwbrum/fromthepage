require 'spec_helper'

RSpec.describe OwnerExporter do
  subject(:exporter) { Class.new { include OwnerExporter }.new }

  describe '#owner_mailing_list_csv' do
    let(:collection_one) { instance_double(Collection, id: 2, title: 'Collection Two') }
    let(:collection_two) { instance_double(Collection, id: 1, title: 'Collection One') }
    let(:owner) { instance_double(User, collections: [collection_one, collection_two]) }
    let(:user_one) do
      instance_double(User, id: 10, login: 'user-one', display_name: 'User One', email: 'one@example.com', activity_email: true)
    end
    let(:user_two) do
      instance_double(User, id: 11, login: 'user-two', display_name: 'User Two', email: 'two@example.com', activity_email: false)
    end
    let(:deed_counts) { { [user_one.id, 1] => 2, [user_one.id, 2] => 1, [user_two.id, 2] => 3 } }

    before do
      deed_relation = double('Deed relation')
      grouped_deeds = double('Grouped deed relation')
      allow(Deed).to receive(:where).with(collection_id: [1, 2]).and_return(deed_relation)
      allow(deed_relation).to receive(:group).with(:user_id, :collection_id).and_return(grouped_deeds)
      allow(grouped_deeds).to receive(:count).and_return(deed_counts)
      collection_relation = double('Collection relation')
      allow(Collection).to receive(:where).with(id: [1, 2]).and_return(collection_relation)
      allow(collection_relation).to receive(:order).with(:id).and_return([collection_two, collection_one])
      allow(User).to receive(:find).with([user_one.id, user_two.id]).and_return([user_one, user_two])
    end

    it 'exports users with deed counts per owner collection' do
      csv = CSV.parse(exporter.owner_mailing_list_csv(owner))

      expect(csv.first).to eq(['User Login', 'User Name', 'Email', 'Opt-In', 'Collection One', 'Collection Two'])
      expect(csv.second).to eq(['user-one', 'User One', 'one@example.com', 'true', '2', '1'])
      expect(csv.third).to eq(['user-two', 'User Two', 'two@example.com', 'false', '0', '3'])
    end
  end

  describe '#detailed_activity_csv' do
    let!(:owner) { build(:owner).tap { |o| o.save(validate: false) } }
    let!(:other_owner) { build(:owner).tap { |o| o.save(validate: false) } }
    let!(:collection_one) { create(:collection, owner_user_id: owner.id) }
    let!(:collection_two) { create(:collection, owner_user_id: owner.id) }
    let!(:other_collection) { create(:collection, owner_user_id: other_owner.id) }
    let!(:user_one) do
      build(:user, login: 'alpha-user', display_name: 'Alpha User', email: 'alpha@example.com').tap { |u| u.save(validate: false) }
    end
    let!(:user_two) do
      build(:user, login: 'beta-user', display_name: 'Beta User', email: 'beta@example.com').tap { |u| u.save(validate: false) }
    end
    let!(:user_three) do
      build(:user, login: 'gamma-user', display_name: 'Gamma User', email: 'gamma@example.com').tap { |u| u.save(validate: false) }
    end
    let(:start_date) { Date.new(2026, 1, 1) }
    let(:end_date) { Date.new(2026, 1, 3) }

    before do
      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: collection_one.id, date: start_date, activity: 'transcribe', minutes: 15)
      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: collection_two.id, date: start_date, activity: 'review', minutes: 10)
      create(:ahoy_activity_summary, user_id: user_one.id, collection_id: collection_two.id, date: start_date + 1.day, activity: 'translate', minutes: 30)
      create(:ahoy_activity_summary, user_id: user_two.id, collection_id: collection_one.id, date: start_date, activity: 'transcribe', minutes: 5)
      create(:ahoy_activity_summary, user_id: user_two.id, collection_id: collection_one.id, date: end_date, activity: 'translate', minutes: 20)
      create(:ahoy_activity_summary, user_id: user_three.id, collection_id: other_collection.id, date: start_date + 1.day, activity: 'transcribe', minutes: 999)
    end

    it 'exports headers and per-day activity with zero fill' do
      csv = CSV.parse(exporter.detailed_activity_csv(owner, start_date, end_date), headers: true)

      expect(csv.headers).to eq(['Username', 'Email', 'Jan 01, 2026', 'Jan 02, 2026', 'Jan 03, 2026'])
      expect(csv.map { |row| row['Username'] }).to eq([user_one.display_name, user_two.display_name])
      expect(csv.map { |row| row['Email'] }).to eq(['alpha@example.com', 'beta@example.com'])
      expect(csv[0].fields).to eq([user_one.display_name, 'alpha@example.com', '25', '30', '0'])
      expect(csv[1].fields).to eq([user_two.display_name, 'beta@example.com', '5', '0', '20'])
    end

    it 'does not duplicate users with activity across multiple owned collections' do
      csv = CSV.parse(exporter.detailed_activity_csv(owner, start_date, end_date), headers: true)
      usernames = csv.map { |row| row['Username'] }

      expect(usernames.size).to eq(2)
      expect(usernames.uniq.size).to eq(2)
      expect(csv.map { |row| row['Email'] }).to contain_exactly('alpha@example.com', 'beta@example.com')
    end

    it 'executes a single grouped sum query across all contributors' do
      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        sql = payload[:sql]
        next if payload[:name] == 'SCHEMA'
        next unless sql.include?('ahoy_activity_summaries')

        queries << sql
      end

      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        exporter.detailed_activity_csv(owner, start_date, end_date)
      end

      sum_queries = queries.grep(/SELECT\s+SUM\(/i)
      expect(sum_queries.size).to eq(1)
      expect(sum_queries.first).to match(/GROUP BY.*user_id.*date/i)
    end
  end
end
