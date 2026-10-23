require 'spec_helper'

RSpec.describe QualitySampling, type: :model do
  describe 'sample set serialization' do
    it 'returns an empty array when blank' do
      expect(described_class.new.sample_set).to eq([])
    end

    it 'serializes arrays as JSON' do
      sampling = described_class.new

      sampling.sample_set = [1, 2, 3]

      expect(sampling[:sample_set]).to eq('[1,2,3]')
      expect(sampling.sample_set).to eq([1, 2, 3])
      expect(sampling.sample_page_count).to eq(3)
    end
  end

  describe 'page helpers' do
    let(:collection) { create(:collection, works: []) }
    let(:work) { create(:work, collection: collection) }
    let!(:review_page) { create(:page, work: work, status: :needs_review, approval_delta: 2) }
    let!(:completed_page) { create(:page, work: work, status: :transcribed, approval_delta: 5) }
    let(:sampling) { described_class.new(collection: collection, sample_set: [review_page.id, completed_page.id]) }

    it 'finds sampled pages that still need review' do
      expect(sampling.needs_review_pages).to contain_exactly(review_page)
      expect(sampling.next_unsampled_page).to eq(review_page)
    end

    it 'finds a page index within the sample' do
      expect(sampling.index_within_sample(completed_page)).to eq(1)
    end

    it 'reports whether the full sample has been reviewed' do
      expect(sampling.sampled?).to be false

      review_page.update!(status: :transcribed)

      expect(sampling.sampled?).to be true
    end

    it 'returns the maximum approval delta in the sample' do
      expect(sampling.max_approval_delta).to eq(5)
    end
  end

  describe '#sampling_objects' do
    it 'summarizes sampled pages by work and last editor' do
      collection = create(:collection, works: [])
      work = create(:work, collection: collection)
      editor = create(:user)
      corrected_page = create(:page, work: work, status: :transcribed, last_editor_user_id: editor.id, approval_delta: 4)
      clean_page = create(:page, work: work, status: :blank, last_editor_user_id: editor.id, approval_delta: 0)
      unreviewed_page = create(:page, work: work, status: :needs_review, last_editor_user_id: editor.id, approval_delta: nil)
      sampling = described_class.new(sample_set: [corrected_page.id, clean_page.id, unreviewed_page.id])

      work_hash, user_hash = sampling.sampling_objects

      expect(work_hash[work.id]).to have_attributes(total_page_count: 3, reviewed_page_count: 2, approval_delta_sum: 4.0, corrected_page_count: 1)
      expect(work_hash[work.id].mean_approval_delta).to eq(2.0)
      expect(user_hash[editor.id]).to have_attributes(total_page_count: 2, reviewed_page_count: 2, approval_delta_sum: 4.0, corrected_page_count: 1)
    end
  end
end
