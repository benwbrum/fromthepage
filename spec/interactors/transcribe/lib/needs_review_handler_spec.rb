require 'spec_helper'

describe Transcribe::Lib::NeedsReviewHandler do
  let(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  let(:type) { :transcription }
  let(:save_to_needs_review) { false }

  let(:page_params) { { needs_review: '1' } }

  let(:result) do
    described_class.new(
      page: page,
      page_params: page_params,
      user: owner,
      type: type,
      save_to_needs_review: save_to_needs_review
    ).perform
  end

  context 'when type transcription' do
    context 'when clicked saved_to_needs_review and review_workflow' do
      let(:save_to_needs_review) { true }
      let!(:collection) { create(:collection, :review_required, owner_user_id: owner.id) }

      it 'updates status to needs_review' do
        expect { result }.to change { Deed.count }.by(1)
        expect(result.status_needs_review?).to be_truthy
      end

      context 'when page is already needs_review' do
        let!(:page) { create(:page, work: work, status: :needs_review) }

        it 'does not change status' do
          expect { result }.not_to(change { Deed.count })
          expect(result.status_needs_review?).to be_truthy
        end
      end
    end

    context 'when needs_review is checked' do
      it 'updates status to needs_review' do
        expect { result }.to change { Deed.count }.by(1)
        expect(result.status_needs_review?).to be_truthy
      end

      context 'when page is already needs_review' do
        let!(:page) { create(:page, work: work, status: :needs_review) }

        it 'does not change status' do
          expect { result }.not_to(change { Deed.count })
          expect(result.status_needs_review?).to be_truthy
        end
      end
    end

    context 'when needs_review is unchecked' do
      let(:page_params) { { needs_review: '0' } }

      it 'does not change status to needs_review' do
        expect { result }.not_to(change { Deed.count })
        expect(result.status_needs_review?).to be_falsey
      end

      context 'when page is already needs_review' do
        let!(:page) { create(:page, work: work, status: :needs_review) }

        it 'changes status to new' do
          expect { result }.to change { Deed.count }.by(1)
          expect(result.status_new?).to be_truthy
        end
      end
    end
  end

  context 'when type translation' do
    let(:type) { :translation }

    context 'when review workflow and translation_status_new' do
      let!(:page) { create(:page, work: work, translation_status: :new) }

      it 'updates translation_status to needs_review' do
        expect { result }.to change { Deed.count }.by(1)
        expect(result.translation_status_needs_review?).to be_truthy
      end
    end

    context 'when needs_review is checked' do
      it 'updates translation status to needs_review' do
        expect { result }.to change { Deed.count }.by(1)
        expect(result.translation_status_needs_review?).to be_truthy
      end

      context 'when page is already needs_review' do
        let!(:page) { create(:page, work: work, translation_status: :needs_review) }

        it 'does not change status' do
          expect { result }.not_to(change { Deed.count })
          expect(result.translation_status_needs_review?).to be_truthy
        end
      end
    end

    context 'when needs_review is unchecked' do
      let(:page_params) { { needs_review: '0' } }

      it 'does not change translation status to needs_review' do
        expect { result }.not_to(change { Deed.count })
        expect(result.status_needs_review?).to be_falsey
      end

      context 'when page is already needs_review' do
        let!(:page) { create(:page, work: work, translation_status: :needs_review) }

        it 'changes translation status to new' do
          expect { result }.to change { Deed.count }.by(1)
          expect(result.translation_status_new?).to be_truthy
        end
      end
    end
  end
end
