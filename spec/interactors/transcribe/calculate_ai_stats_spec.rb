require 'spec_helper'

describe Transcribe::CalculateAiStats do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }

  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:page) { create(:page, work: work, source_text: "This is a Human Generated text", xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>This is a Human Generated text</p></page>") }
  let!(:ai_transcription) { create(:ai_transcription, page_id: page.id, status: :finished, source_text: "This is an AI Generated text") }
  let!(:unfinished_ai_transcription) { create(:ai_transcription, page_id: page.id, status: :processing) }

  let(:result) { described_class.new(page: page).call }

  it 'calculates ai stats for finished ai_transcriptions' do
    expect(ai_transcription).to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )
    expect(unfinished_ai_transcription).to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )

    expect(result.success?).to be_truthy

    expect(ai_transcription.reload).not_to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )
    expect(unfinished_ai_transcription).to have_attributes(
      verbatim_wer: nil,
      verbatim_cer: nil,
      text_wer: nil,
      text_cer: nil
    )
  end
end
