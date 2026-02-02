require 'spec_helper'

describe Page::CalculateApprovalDeltaJob do
  include ActiveJob::TestHelper

  before do
    Current.user = user
  end

  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work, status: status) }

  subject(:worker) { described_class.new }

  let(:status) { :new }

  let(:perform_worker) do
    worker.perform(page_id: page.id, user_id: user.id)
  end

  context 'when not-completed status' do
    before do
      # Mock approval delta
      page.update_column(:approval_delta, 20)
    end

    it 'zero out deltas' do
      perform_enqueued_jobs do
        perform_worker
      end

      expect(page.reload.approval_delta).to be_nil
    end
  end

  context 'when blank transcriptions' do
    let(:status) { :blank }

    before do
      # Mock approval delta
      page.update_column(:approval_delta, 20)
    end

    it 'zero out deltas' do
      perform_enqueued_jobs do
        perform_worker
      end

      expect(page.reload.approval_delta).to be_nil
    end
  end

  context 'without most_recent_approver_version' do
    let(:status) { :transcribed }

    let!(:page) { create(:page, work: work, status: status, source_text: 'New Transcription') }

    it 'calculates delta' do
      perform_enqueued_jobs do
        perform_worker
      end

      expect(page.reload.approval_delta.round(2)).to eq(1.0)
    end
  end

  context 'with most_recent_approver_version' do
    let(:status) { :transcribed }

    let!(:user_2) { create(:unique_user) }

    let!(:page) { create(:page, work: work, status: status, source_text: 'Old Transcription') }
    let!(:page_version) { create(:page_version, user_id: user_2.id, page_id: page.id, transcription: 'Old Transcription') }

    it 'calculates delta' do
      page.update_column(:source_text, 'New Transcription')

      perform_enqueued_jobs do
        perform_worker
      end

      expect(page.reload.approval_delta.round(2)).to eq(0.09)
    end
  end
end
