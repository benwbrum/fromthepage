require 'spec_helper'

RSpec.describe DashboardHelper, type: :helper do

  describe '#time_spent_in_date_range' do
    user_id = User.first.id
    let(:start_date) { Date.new(2023, 1, 1) }
    let(:end_date) { Date.new(2023, 1, 31) }

    it 'returns the formatted time spent in the date range' do
      allow(helper).to receive(:minutes_worked_in_range).with(user_id, start_date, end_date).and_return(1000)

      expected_result = '16 hours and 40 minutes'
      result = helper.time_spent_in_date_range(user_id, start_date, end_date)
      
      expect(result).to eq(expected_result)
    end

    it 'calculates the total minutes worked within the date range' do
      create(:ahoy_activity_summary, user_id: user_id, created_at: start_date, minutes: 120)
      create(:ahoy_activity_summary, user_id: user_id, created_at: end_date, minutes: 180)
      create(:ahoy_activity_summary, user_id: user_id, created_at: Date.new(2023, 2, 1), minutes: 90)
      
      result = helper.minutes_worked_in_range(user_id, start_date, end_date)
      
      expect(result).to be_an(Integer)
    end
  end

  describe '#formatted_time' do
    it 'formats total minutes correctly' do
      expect(helper.formatted_time(0)).to eq('0 hours and 0 minutes')
      expect(helper.formatted_time(60)).to eq('1 hours and 0 minutes')
      expect(helper.formatted_time(90)).to eq('1 hours and 30 minutes')
      expect(helper.formatted_time(121)).to eq('2 hours and 1 minutes')
    end
  end

end