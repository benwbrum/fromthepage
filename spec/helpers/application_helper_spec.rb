require 'spec_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe 'filtered_page_entries_info' do
    let(:model_name) { double('ModelName', human: 'Work', name: 'Work') }
    let(:collection) do
      double('Collection',
        model_name: model_name,
        total_pages: 1,
        offset: 0,
        length: 2,
        total_entries: 2
      )
    end

    context 'when showing all works (not filtered)' do
      it 'uses default page_entries_info' do
        expect(helper).to receive(:page_entries_info).with(collection).and_return("Displaying all 2 works")
        result = helper.filtered_page_entries_info(collection, false)
        expect(result).to eq("Displaying all 2 works")
      end
    end

    context 'when showing filtered works' do
      context 'with multiple filtered works on single page' do
        it 'returns filtered message' do
          result = helper.filtered_page_entries_info(collection, true)
          expect(result).to include('2 filtered works')
          expect(result).not_to include('all')
        end
      end

      context 'with single filtered work' do
        let(:single_collection) do
          double('Collection',
            model_name: model_name,
            total_pages: 1,
            offset: 0,
            length: 1,
            total_entries: 1
          )
        end

        it 'returns singular filtered message' do
          result = helper.filtered_page_entries_info(single_collection, true)
          expect(result).to include('1 filtered work')
          expect(result).not_to include('all')
        end
      end

      context 'with no filtered works' do
        let(:empty_collection) do
          double('Collection',
            model_name: model_name,
            total_pages: 1,
            offset: 0,
            length: 0,
            total_entries: 0
          )
        end

        it 'returns no works found message' do
          result = helper.filtered_page_entries_info(empty_collection, true)
          expect(result).to include('No works found')
        end
      end
    end
  end
end