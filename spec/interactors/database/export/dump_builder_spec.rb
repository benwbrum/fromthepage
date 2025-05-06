require 'spec_helper'

describe Database::Export::DumpBuilder do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:work_statistic) { create(:work_statistic, work: work) }
  let!(:page) { create(:page, work: work) }
  let(:path) { '/tmp/dumps/test' }

  let(:result) do
    described_class.new(collection_slugs: [collection.slug], path: path).call
  end

  before do
    dir = Rails.root.join(path)

    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
  end

  it 'creates dumps' do
    expect(result.success?).to be_truthy
    expect(Dir.children(path).count { |f| File.file?(File.join(path, f)) }).to eq(32)
  end
end
