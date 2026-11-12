require 'spec_helper'

describe AiWorkMetadata::StartRun do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:field) { create(:transcription_field, :as_metadata, :text_field, label: 'Title', collection: collection) }
  let(:long) { ' Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor.' * 3 }
  let!(:works) do
    Array.new(3) { |i| create(:work, collection: collection, title: "Work #{i}", pages: []) }
  end
  let!(:pages) { works.map { |work| create(:page, work: work, status: :new) } }

  before do
    Current.user = owner
    ActiveJob::Base.queue_adapter = :test
  end

  def start(kind = :sample)
    AiWorkMetadata::StartRun.new(collection: collection, user: owner, kind: kind).call
  end

  def transcribe_all(status: :finished)
    AiTranscription.where(page_id: pages.map(&:id)).delete_all
    pages.each_with_index { |page, i| create(:ai_transcription, page_id: page.id, status: status, source_text: "Text #{i}.#{long}") }
  end

  context 'when pages have no AI transcription' do
    it 'transcribes the collection first and waits before choosing the sample or drafting' do
      result = nil
      expect { result = start }.to have_enqueued_job(AiTranscription::BulkGenerateJob)
        .and have_enqueued_job(AiWorkMetadata::StartRunJob)
      expect(result).to be_success
      expect(result.run).to be_waiting
      expect(AiTranscription.where(page_id: pages.map(&:id)).count).to eq(3)
      expect(described_class.sample_set(collection)).to be_nil
      expect(AiWorkMetadata.where(work_id: works.map(&:id))).to be_empty
    end

    it 'does not start a second run while one is waiting' do
      start
      expect(start).not_to be_success
      expect(collection.ai_work_metadata_runs.count).to eq(1)
    end
  end

  describe AiWorkMetadata::StartRunJob do
    let!(:run) { start.run }

    it 'keeps waiting while transcription is in progress' do
      expect { described_class.perform_now(user_id: owner.id, run_id: run.id) }.to have_enqueued_job(described_class).with(user_id: owner.id, run_id: run.id)
      expect(run.reload).to be_waiting
    end

    it 'chooses the sample from the transcribed works and queues drafts once every page is transcribed' do
      transcribe_all
      expect { described_class.perform_now(user_id: owner.id, run_id: run.id) }.to have_enqueued_job(AiWorkMetadata::BulkGenerateJob)
      expect(run.reload).not_to be_waiting
      expect(AiWorkMetadata::StartRun.sample_set(collection).works).to match_array(works)
      expect(run.ai_work_metadata.pluck(:work_id)).to match_array(works.map(&:id))
    end

    it 'does not hold drafting up for pages whose transcription failed' do
      transcribe_all
      AiTranscription.find_by(page_id: pages.first.id).update!(status: :error)
      described_class.perform_now(user_id: owner.id, run_id: run.id)
      expect(run.reload).not_to be_waiting
    end

    it 'transcribes pages added while waiting' do
      transcribe_all
      new_page = create(:page, work: works.first, status: :new)
      expect { described_class.perform_now(user_id: owner.id, run_id: run.id) }.to have_enqueued_job(AiTranscription::BulkGenerateJob)
      expect(AiTranscription.where(page_id: new_page.id)).to exist
      expect(run.reload).to be_waiting
    end
  end

  it 'starts drafting straight away when the collection is already transcribed' do
    transcribe_all
    result = nil
    expect { result = start(:all) }.not_to have_enqueued_job(AiTranscription::BulkGenerateJob)
    expect(result.run).not_to be_waiting
    expect(result.run.ai_work_metadata.pluck(:status).uniq).to eq(['new'])
  end
end
