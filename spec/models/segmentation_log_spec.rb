require 'spec_helper'

describe SegmentationLog do
  describe '#total_token_count' do
    it 'sums prompt, candidates, and thoughts tokens from metadata' do
      log = build(:segmentation_log, metadata: {
        'prompt_token_count' => 100,
        'candidates_token_count' => 5,
        'thoughts_token_count' => 20,
        'total_token_count' => 125
      })

      expect(log.total_token_count).to eq(125)
    end

    it 'treats missing token keys as zero' do
      log = build(:segmentation_log, metadata: { 'prompt_token_count' => 40 })

      expect(log.total_token_count).to eq(40)
    end

    it 'is zero when there is no metadata' do
      log = build(:segmentation_log, metadata: nil)

      expect(log.total_token_count).to eq(0)
    end
  end

  describe 'status' do
    it 'defaults to finished' do
      expect(SegmentationLog.new.status).to eq('finished')
    end
  end
end
