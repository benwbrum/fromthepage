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

  it 'creates the sample set, drafts for its works, and queues generation' do
    expect(AiWorkMetadata::BulkGenerateJob).to receive(:perform_later) do |args|
      expect(args[:scope][:work_ids]).to match_array(works.map(&:id))
    end

    perform_job

    expect(collection.document_sets.find_by(title: SubjectHeadings::CreateSampleSet::TITLE).works).to match_array(works)
    drafts = AiWorkMetadata.where(work_id: works.map(&:id))
    expect(drafts.size).to eq(3)
    expect(drafts.map(&:model).uniq).to eq([AiWorkMetadata::SUBJECT_HEADING_MODEL])
    expect(drafts.map(&:status).uniq).to eq(['processing'])
  end

  context 'when the sample set already exists' do
    before { create(:document_set, collection: collection, owner_user_id: owner.id, title: SubjectHeadings::CreateSampleSet::TITLE) }

    it 'raises without queuing drafts' do
      expect(AiWorkMetadata::BulkGenerateJob).not_to receive(:perform_later)
      expect { perform_job }.to raise_error(ArgumentError, /already has/)
    end
  end
end
