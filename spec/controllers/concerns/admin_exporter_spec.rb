require 'spec_helper'

RSpec.describe AdminExporter do
  subject(:exporter) { Class.new { include AdminExporter }.new }

  describe '#admin_searches_csv' do
    let(:start_date) { Time.zone.parse('2026-01-01 10:00:00') }
    let(:end_date) { Time.zone.parse('2026-01-02 10:00:00') }
    let(:collection) { instance_double(Collection, title: 'Letters Collection') }
    let(:work) { instance_double(Work, id: 456, title: 'Diary Work') }
    let(:search) do
      instance_double(
        SearchAttempt,
        query: 'needle',
        created_at: start_date + 1.hour,
        search_type: 'collection',
        collection: collection,
        collection_id: 123,
        work: work,
        hits: 7,
        clicks: 2,
        contributions: 1,
        visit_id: 55,
        user_id: 66,
        owner: true
      )
    end
    let(:search_without_associations) do
      instance_double(
        SearchAttempt,
        query: 'orphan',
        created_at: start_date + 2.hours,
        search_type: 'site',
        collection: nil,
        collection_id: nil,
        work: nil,
        hits: 0,
        clicks: 0,
        contributions: 0,
        visit_id: nil,
        user_id: nil,
        owner: false
      )
    end

    before do
      relation = double('SearchAttempt relation')
      allow(SearchAttempt).to receive(:where).and_return(relation)
      allow(relation).to receive(:order).with(:created_at).and_return([search, search_without_associations])
    end

    it 'exports search attempts with headers and associated titles' do
      csv = CSV.parse(exporter.admin_searches_csv(start_date, end_date))

      expect(csv.first).to eq([
        'Query', 'Date', 'Search Type', 'Collection Title', 'Collection ID', 'Work Title', 'Work ID',
        'Hits', 'Clicks', 'Contributions', 'Visit ID', 'User ID', 'Owner'
      ])
      expect(csv.second).to eq([
        'needle', search.created_at.to_s, 'collection', 'Letters Collection', '123', 'Diary Work', '456',
        '7', '2', '1', '55', '66', 'true'
      ])
    end

    it 'uses blank values when collection or work is missing' do
      csv = CSV.parse(exporter.admin_searches_csv(start_date, end_date))

      expect(csv.third).to eq([
        'orphan', search_without_associations.created_at.to_s, 'site', nil, nil, nil, nil,
        '0', '0', '0', nil, nil, 'false'
      ])
    end

    it 'queries the requested date range by full days' do
      exporter.admin_searches_csv(start_date, end_date)

      expect(SearchAttempt).to have_received(:where).with(
        'created_at BETWEEN ? AND ?',
        start_date.beginning_of_day,
        end_date.end_of_day
      )
    end
  end
end
