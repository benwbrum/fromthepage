require 'spec_helper'

describe Transcribe::MarkAsBlank do
  let(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work) }

  let(:result) do
    described_class.new(
      page: page,
      user: owner
    ).call
  end

  it 'updates page status to blank' do
    expect { result }.to change { Deed.count }.by(1)
    expect(result.success?).to be_truthy
    expect(page.reload.status_blank?).to be_truthy
  end

  context 'when page is already status blank' do
    let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

    it 'does not make any change' do
      expect { result }.not_to change Deed.count
      expect(result.success?).to be_truthy
    end
  end
end
