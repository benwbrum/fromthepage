require 'spec_helper'

RSpec.describe AdminHelper, type: :helper do
  describe '#format_date_or_dash' do
    it 'returns a dash when the date is nil' do
      expect(helper.format_date_or_dash(nil)).to eq('-')
    end

    it 'formats a date using an abbreviated month name' do
      expect(helper.format_date_or_dash(Date.new(2026, 6, 19))).to eq('Jun 19, 2026')
    end
  end
end
