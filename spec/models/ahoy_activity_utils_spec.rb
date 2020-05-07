require 'spec_helper'
require 'ahoy_activity_utils'

RSpec.describe AhoyActivityUtils do

  describe 'Static Methods' do
    it "finds correct difference between two times" do
        after   = 15.minutes.ago
        before  = 20.minutes.ago

        duration = AhoyActivityUtils.total_contiguous_seconds([before, after])

        expect(duration).to eq(5.minutes)
    end
    it "sums contiguous times" do
        later   = 10.minutes.ago
        after   = 15.minutes.ago
        before  = 20.minutes.ago

        duration = AhoyActivityUtils.total_contiguous_seconds([before, after, later])

        expect(duration).to eq(10.minutes)
    end
    it "finds correct difference between two dates regardless of order" do
        later   = 10.minutes.ago
        after   = 15.minutes.ago
        before  = 20.minutes.ago

        duration_a = AhoyActivityUtils.total_contiguous_seconds([before, after, later])
        duration_b = AhoyActivityUtils.total_contiguous_seconds([after, later, before])
        duration_c = AhoyActivityUtils.total_contiguous_seconds([later, before, after])

        expect(duration_a).to eq(10.minutes)
        expect(duration_b).to eq(10.minutes)
        expect(duration_c).to eq(10.minutes)
    end

    it "skips times greater than 60 minutes apart by default" do
        after   = 10.minutes.ago
        before  = 70.minutes.ago

        duration = AhoyActivityUtils.total_contiguous_seconds([before, after])

        expect(duration).to eq(0)
    end

    it "skips times greater than specified tolerance" do
        after   = 10.minutes.ago
        before  = 70.minutes.ago

        duration = AhoyActivityUtils.total_contiguous_seconds([before, after], 61.minutes)

        expect(duration).to eq(60.minutes)
    end

    it "sums contiguous elements, skips non-contiguous gaps" do
        times = [1.day.ago, (1.day.ago + 30.minutes), 60.minutes.ago, 30.minutes.ago]
        
        duration = AhoyActivityUtils.total_contiguous_seconds(times)
        
        expect(duration).to eq(60.minutes)
    end
    it "sums shuffled timestamps correctly" do
        times = [1.day.ago, (1.day.ago + 30.minutes), 60.minutes.ago, 30.minutes.ago].shuffle
        
        duration = AhoyActivityUtils.total_contiguous_seconds(times)
        
        expect(duration).to eq(60.minutes)
    end
  end
end

