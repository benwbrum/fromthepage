require 'spec_helper'

describe 'ExportService#export_page_details_as_csv' do
  include ExportService
  include Rails.application.routes.url_helpers

  before do
    Current.user = owner
  end

  let(:owner) { User.find_by(login: OWNER) }
  let(:user) { User.find_by(login: USER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page1) { create(:page, work: work, title: 'Page 1', position: 1, status: 'transcribed') }
  let!(:page2) { create(:page, work: work, title: 'Page 2', position: 2, status: 'needs_review') }
  let!(:deed) { create(:deed, work: work, page: page1, user: user, deed_type: DeedType::PAGE_TRANSCRIPTION) }

  describe 'collection-level export' do
    it 'exports CSV with page and work details' do
      csv_string = export_page_details_as_csv(collection)
      csv = CSV.parse(csv_string, headers: true)

      # Check headers exist
      expect(csv.headers).to include('Page URL')
      expect(csv.headers).to include('Page Title')
      expect(csv.headers).to include('Page Position')
      expect(csv.headers).to include('Page Status')
      expect(csv.headers).to include('Work Title')
      expect(csv.headers).to include('Work Identifier')

      # Check we have rows for pages in our test work
      # Filter to just the pages from our specific work
      work_rows = csv.select { |row| row['Work Title'] == work.title }
      expect(work_rows.length).to eq(2)

      # Check first page data
      first_row = work_rows.find { |row| row['Page Title'] == 'Page 1' }
      expect(first_row).not_to be_nil
      expect(first_row['Page Position']).to eq('1')
      expect(first_row['Work Title']).to eq(work.title)

      # Check second page data
      second_row = work_rows.find { |row| row['Page Title'] == 'Page 2' }
      expect(second_row).not_to be_nil
      expect(second_row['Page Position']).to eq('2')
      expect(second_row['Work Title']).to eq(work.title)
    end
  end

  describe 'work-level export' do
    it 'exports CSV with page and work details for a single work' do
      csv_string = export_page_details_as_csv(work)
      csv = CSV.parse(csv_string, headers: true)

      # Check we have rows for pages in this work only
      expect(csv.length).to eq(2)

      # Check work info is consistent across rows
      csv.each do |row|
        expect(row['Work Title']).to eq(work.title)
      end
    end
  end
end
