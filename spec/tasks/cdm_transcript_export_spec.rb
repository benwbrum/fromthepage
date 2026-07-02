require 'spec_helper'
require 'rake'

describe 'fromthepage:cdm_transcript_export' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  let(:owner)      { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }

  let(:complete_work) do
    create(:work, collection: collection).tap do |w|
      create(:sc_manifest, work: w)
      w.work_statistic.update!(complete: 100)
    end
  end

  let(:incomplete_work) do
    create(:work, collection: collection).tap do |w|
      create(:sc_manifest, work: w)
      w.work_statistic.update!(complete: 50)
    end
  end

  before do
    complete_work
    incomplete_work
    allow(ContentdmTranslator).to receive(:export_work_to_cdm_with_retry)
    allow(SystemMailer).to receive_message_chain(:cdm_sync_finished, :deliver!)
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
  ensure
    $stdout = original
  end

  def run_task
    Rake::Task['fromthepage:cdm_transcript_export'].reenable
    capture_stdout { Rake::Task['fromthepage:cdm_transcript_export'].invoke(collection.slug) }
  end

  context 'with human_only setting (default)' do
    before { create(:cdm_export_setting, collection: collection) }

    it 'exports complete works' do
      run_task
      expect(ContentdmTranslator).to have_received(:export_work_to_cdm_with_retry).with(complete_work, any_args)
    end

    it 'skips incomplete works' do
      run_task
      expect(ContentdmTranslator).not_to have_received(:export_work_to_cdm_with_retry).with(incomplete_work, any_args)
    end
  end

  context 'with human_and_ai setting' do
    before { create(:cdm_export_setting, :human_and_ai, collection: collection) }

    it 'exports complete works' do
      run_task
      expect(ContentdmTranslator).to have_received(:export_work_to_cdm_with_retry).with(complete_work, any_args)
    end

    it 'also exports incomplete works' do
      run_task
      expect(ContentdmTranslator).to have_received(:export_work_to_cdm_with_retry).with(incomplete_work, any_args)
    end
  end

  context 'with a document set argument' do
    let(:document_set) { create(:document_set, collection: collection, owner_user_id: owner.id) }
    let(:outside_work) do
      create(:work, collection: collection).tap do |w|
        create(:sc_manifest, work: w)
        w.work_statistic.update!(complete: 100)
      end
    end

    before do
      create(:cdm_export_setting, collection: collection)
      document_set.works << complete_work
      outside_work
    end

    def run_document_set_task
      Rake::Task['fromthepage:cdm_transcript_export'].reenable
      capture_stdout { Rake::Task['fromthepage:cdm_transcript_export'].invoke(document_set.slug) }
    end

    it 'exports only works in the document set' do
      run_document_set_task
      expect(ContentdmTranslator).to have_received(:export_work_to_cdm_with_retry).with(complete_work, any_args)
      expect(ContentdmTranslator).not_to have_received(:export_work_to_cdm_with_retry).with(outside_work, any_args)
    end
  end

  context 'with no cdm_export_setting record' do
    it 'exports only complete works' do
      run_task
      expect(ContentdmTranslator).to have_received(:export_work_to_cdm_with_retry).with(complete_work, any_args)
      expect(ContentdmTranslator).not_to have_received(:export_work_to_cdm_with_retry).with(incomplete_work, any_args)
    end
  end
end
