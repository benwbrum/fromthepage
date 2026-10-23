require 'spec_helper'

RSpec.describe QualitySamplingsHelper, type: :helper do
  describe '#approval_delta_to_quintile' do
    it 'returns zero when max approval delta is nil or zero' do
      expect(helper.approval_delta_to_quintile(10, nil)).to eq(0)
      expect(helper.approval_delta_to_quintile(10, 0)).to eq(0)
    end

    it 'rounds the mean as a proportion of the max into four quintile steps' do
      expect(helper.approval_delta_to_quintile(25.0, 100.0)).to eq(1)
      expect(helper.approval_delta_to_quintile(50.0, 100.0)).to eq(2)
      expect(helper.approval_delta_to_quintile(90.0, 100.0)).to eq(4)
    end
  end

  describe '#approval_delta_to_style' do
    it 'includes the calculated quintile in the css class' do
      expect(helper.approval_delta_to_style(50.0, 100.0)).to eq('approval-delta approval-delta-2')
    end
  end

  describe '#approval_delta_to_display' do
    it 'translates the calculated quintile key' do
      expect(helper).to receive(:t).with('.approval_delta_display_2').and_return('Medium')

      expect(helper.approval_delta_to_display(50.0, 100.0)).to eq('Medium')
    end
  end
end
