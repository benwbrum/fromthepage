require 'spec_helper'

describe SubjectHeadings::SampleSetJob do
  include ActiveJob::TestHelper

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, label: 'Subject', input_type: 'subject_headings', collection: collection) }
  let!(:works) do
    Array.new(3) do |i|
      create(:work, collection: collection).tap do |work|
        create(:page, :transcribed, work: work,
                      xml_text: "<?xml version='1.0' encoding='UTF-8'?><page><p>Document #{i} #{'about something in particular ' * 10}</p></page>")
      end
    end
  end

  let(:perform_job) { described_class.perform_now(user_id: owner.id, collection_id: collection.id) }

  # Drafting waits for every page to have an AI transcription (see AiWorkMetadata::StartRunJob)
  before do
    Page.where(work_id: works.map(&:id)).find_each { |page| create(:ai_transcription, page_id: page.id, status: :finished, source_text: 'AI text') }
  end

  it 'creates the sample set, drafts for its works, and queues generation' do
    expect(AiWorkMetadata::BulkGenerateJob).to receive(:perform_later) do |args|
      expect(args[:scope][:work_ids]).to match_array(works.map(&:id))
    end

    perform_job

    expect(collection.document_sets.find_by(title: SubjectHeadings::CreateSampleSet::TITLE).works).to match_array(works)
    drafts = AiWorkMetadata.where(work_id: works.map(&:id))
    expect(drafts.size).to eq(3)
    expect(drafts.map(&:model).uniq).to eq([AiWorkMetadata::SUBJECT_HEADING_MODEL])
    expect(drafts.map(&:status).uniq).to eq(['new'])
    expect(drafts.map(&:ai_work_metadata_run).uniq).to eq([collection.ai_work_metadata_runs.find_by!(kind: 'sample')])
  end

  context 'when the sample set already exists' do
    let!(:sample_set) do
      create(:document_set, collection: collection, owner_user_id: owner.id, title: SubjectHeadings::CreateSampleSet::TITLE).tap do |set|
        set.update!(work_ids: [works.first.id])
      end
    end

    it 'drafts the existing sample instead of creating another' do
      expect(AiWorkMetadata::BulkGenerateJob).to receive(:perform_later) do |args|
        expect(args[:scope][:work_ids]).to eq([works.first.id])
      end

      expect { perform_job }.not_to change(DocumentSet, :count)
    end
  end
end
