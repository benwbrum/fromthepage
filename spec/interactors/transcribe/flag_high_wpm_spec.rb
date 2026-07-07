require 'spec_helper'

describe Transcribe::FlagHighWpm do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:user) { create(:unique_user) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:page) { create(:page, work: work, source_text: initial_source_text) }
  let(:initial_source_text) { '' }

  let(:source_text) do
    'word ' * 100
  end
  let(:current_time) { Time.zone.parse('2026-01-01 12:00:00') }

  let(:result) do
    page.update!(source_text: source_text)

    described_class.new(
      page: page,
      user: user
    ).call
  end

  before do
    allow(Time).to receive(:current).and_return(current_time)

    Ahoy::Event.create!(
      user_id: user.id,
      name: 'transcribe#display_page',
      properties: {
        page_id: page.id,
        collection_id: collection.id
      },
      time: display_time
    )
  end

  context 'when wpm is above threshold for a new transcription' do
    let(:display_time) { current_time - 10.seconds }

    it 'creates high_wpm suspicious behavior with metadata' do
      expect { result }.to change { SuspiciousBehavior.count }.by(1)

      expect(page.suspicious_behaviors.first).to have_attributes(
        behavior_type: 'high_wpm',
        metadata: include(
          'words' => 100,
          'duration_seconds' => 10,
          'wpm' => be > 300
        )
      )
    end
  end

  context 'when page already had a transcription' do
    let(:initial_source_text) { 'existing transcription' }
    let(:display_time) { current_time - 10.seconds }

    it 'does not create suspicious behavior' do
      expect { result }.not_to change { SuspiciousBehavior.count }
    end
  end

  context 'when wpm is below threshold' do
    let(:display_time) { current_time - 30.minutes }

    it 'does not create suspicious behavior' do
      expect { result }.not_to change { SuspiciousBehavior.count }
    end
  end
end
