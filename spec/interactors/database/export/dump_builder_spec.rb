require 'spec_helper'

describe Database::Export::DumpBuilder do
  let(:dump_key) { 'dump_tester' }
  let!(:user) do
    create(
      :unique_user,
      :owner,
      login: "#{dump_key}_login",
      email: "#{dump_key}@sample.com"
    )
  end
  let!(:collection) { create(:collection, :with_picture, title: "Collection #{dump_key}", owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, title: "Work #{dump_key}", owner_user_id: user.id) }
  let!(:work_statistic) { create(:work_statistic, work: work) }
  let!(:page) { create(:page, work: work) }
  let(:path) { "/tmp/dumps/#{dump_key}" }

  let(:result) do
    described_class.new(collection_slugs: [ collection.slug ], path: path).call
  end

  before do
    dir = Rails.root.join(path)

    FileUtils.rm_rf(dir)
    FileUtils.mkdir_p(dir)
  end

  around do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  it 'creates dumps' do
    expect(result.success?).to be_truthy
    expect(Dir.children(path).count { |f| File.file?(File.join(path, f)) }).to eq(35)
  end
end
