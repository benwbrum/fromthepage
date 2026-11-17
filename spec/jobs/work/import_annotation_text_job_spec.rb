require 'spec_helper'

describe Work::ImportAnnotationTextJob do
  include ActiveJob::TestHelper

  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner_user_id: owner.id) }

  before do
    ScManifest.create!(work: work, at_id: 'https://iiif.archive.org/iiif/example/manifest.json')
  end

  it 'imports the annotation text as the requesting user' do
    interactor = instance_double(Work::ImportAnnotationText, success?: true)
    allow(Work::ImportAnnotationText).to receive(:new).with(work: work, user: owner).and_return(interactor)
    allow(interactor).to receive(:call).and_return(interactor)

    described_class.perform_now(user_id: owner.id, work_id: work.id)

    expect(interactor).to have_received(:call)
  end

  it 'raises the failure so the job is retried' do
    error = RuntimeError.new('Could not import annotation text for pages 1')
    interactor = instance_double(Work::ImportAnnotationText, success?: false, full_errors: error)
    allow(Work::ImportAnnotationText).to receive(:new).and_return(interactor)
    allow(interactor).to receive(:call).and_return(interactor)

    expect do
      described_class.new(user_id: owner.id, work_id: work.id).perform(user_id: owner.id, work_id: work.id)
    end.to raise_error(RuntimeError, 'Could not import annotation text for pages 1')
  end

  it 'does nothing for a work that no longer exists' do
    allow(Work::ImportAnnotationText).to receive(:new)

    described_class.perform_now(user_id: owner.id, work_id: -1)

    expect(Work::ImportAnnotationText).not_to have_received(:new)
  end
end
