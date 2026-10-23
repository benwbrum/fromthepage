require 'spec_helper'

describe Transcribe::CalculateAiStatsJob do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }

  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work, source_text: "This is a Human Generated text", xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>This is a Human Generated text</p></page>") }
  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, status: :finished, source_text: "This is an AI Generated text") }

  subject(:worker) { described_class }

  let(:perform_worker) do
    worker.perform_now(page_id: page.id, user_id: user.id)
  end

  it 'calculates ai stats' do
    expect(ai_transcription).to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )

    perform_worker

    expect(ai_transcription.reload).not_to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )
  end
end
