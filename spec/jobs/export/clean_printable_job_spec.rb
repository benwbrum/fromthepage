require 'spec_helper'

describe Export::CleanPrintableJob do
  include ActiveJob::TestHelper

  let(:temp_dir) { 'spec_tmp/printable' }

  let(:past_stub)    { 8.days.ago.strftime('%Y%m%d%H%M%S') }
  let(:now_stub) { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:past_dir) { Rails.root.join(temp_dir, past_stub) }
  let(:now_dir) { Rails.root.join(temp_dir, now_stub) }

  let(:invalid_stub) { 'invalid' }
  let(:invalid_dir) { Rails.root.join(temp_dir, invalid_stub) }

  subject(:worker) { described_class.new }

  before do
    FileUtils.mkdir_p(Rails.root.join(temp_dir))
    FileUtils.mkdir_p(past_dir)
    FileUtils.mkdir_p(now_dir)
    FileUtils.mkdir_p(invalid_dir)
  end

  after do
    FileUtils.rm_rf(Rails.root.join(temp_dir))
  end

  let(:perform_worker) do
    worker.perform(temp_dir: temp_dir)
  end

  it 'cleans up past printable folders and preserves new ones' do
    expect(File.directory?(past_dir)).to be_truthy
    expect(File.directory?(now_dir)).to be_truthy
    expect(File.directory?(invalid_dir)).to be_truthy

    perform_enqueued_jobs do
      perform_worker
    end

    expect(File.directory?(past_dir)).to be_falsey
    expect(File.directory?(now_dir)).to be_truthy
    expect(File.directory?(invalid_dir)).to be_truthy
  end
end
