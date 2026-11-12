require 'spec_helper'

# Drafts launched from the collection AI settings tab (AiWorkMetadataRun) rebuild their prompt
# from the current transcription text, with the run's reviewed examples.
describe AiWorkMetadata::GenerateJob, 'for a run' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, :text_field, label: 'Title', collection: collection) }
  let!(:work) { create(:work, collection: collection, title: 'Letter', pages: []) }
  let!(:page) { create(:page, work: work, status: :new, title: 'Image 1') }
  let!(:ai_text) { create(:ai_transcription, page_id: page.id, status: :finished, source_text: 'AI text for Image 1') }
  let!(:example_work) do
    create(:work, collection: collection, title: 'Reviewed example', pages: []).tap do |example|
      example.update_columns(metadata_description: [{ 'transcription_field_id' => field.id, 'value' => 'Corrected title' }].to_json)
    end
  end
  let!(:run) do
    collection.ai_work_metadata_runs.create!(kind: 'remainder', user: owner, example_work_ids: [example_work.id], started_at: Time.current)
  end
  let!(:draft) do
    create(:ai_work_metadata, work: work, status: :new, prompt: 'stale', ai_work_metadata_run: run, metadata_json: nil, reasoning: nil)
  end
  let(:metadata_generate) { instance_double(AiWorkMetadata::Generate) }

  before do
    Current.user = owner
    allow(AiWorkMetadata::Generate).to receive(:new).and_return(metadata_generate)
    allow(metadata_generate).to receive(:call) do
      expect(draft.reload).to be_status_processing
      instance_double('Result', success?: true, ai_work_metadata: draft.reload)
    end
  end

  def perform
    described_class.new.perform(user_id: owner.id, ai_work_metadata_id: draft.id)
  end

  it 'drafts from the AI transcription with the reviewed examples' do
    perform

    expect(draft.reload).to be_status_finished
    expect(draft.prompt).to include('AI text for Image 1', 'Reviewed example', '"Corrected title"')
    expect(draft.prompt).not_to include('stale')
  end

  it 'does not transcribe pages itself' do
    ai_text.destroy!
    expect { perform }.not_to change(AiTranscription, :count)
  end

  it 'leaves drafts outside a run to the existing prompt' do
    draft.update!(ai_work_metadata_run: nil, status: :processing)

    perform

    expect(draft.reload.prompt).to eq('stale')
  end
end
