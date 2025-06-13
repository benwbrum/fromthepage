require 'spec_helper'

describe Database::Import::DumpIngestor do
  let(:dump_key) { 'dump_tester' }
  let(:path) { "/tmp/dumps/#{dump_key}" }

  let(:user) { User.find_by(email: "#{dump_key}@sample.com") }
  let(:collection) { Collection.find_by(title: "Collection #{dump_key}") }

  let(:result) do
    described_class.new(path: path).call
  end

  around do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  it 'imports dumps' do
    expect(result.success?).to be_truthy

    expect(user.reload).not_to be_nil
    expect(collection.reload).not_to be_nil
  end
end
