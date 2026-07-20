require 'spec_helper'

describe Database::Import::DumpIngestor do
  let(:dump_key) { 'dump_ingestor_tester' }
  let(:path) { "/tmp/dumps/#{dump_key}" }

  let(:user) { User.find_by(email: "#{dump_key}@sample.com") }
  let(:collection) { Collection.find_by(title: "Collection #{dump_key}") }

  let(:result) do
    described_class.new(path: path).call
  end

  before do
    FileUtils.mkdir_p(path)

    Database::Import::DumpIngestor::RECORDS.each_key do |table|
      File.write("#{path}/#{table}.yml", "--- []\n")
    end

    user_id = SecureRandom.random_number(1_000_000_000)
    File.write(
      "#{path}/users.yml",
      YAML.dump([
        {
          'id' => user_id,
          'login' => "#{dump_key}_login",
          'display_name' => "#{dump_key}_display_name",
          'real_name' => "#{dump_key}_real_name",
          'email' => "#{dump_key}@sample.com"
        }
      ])
    )

    File.write(
      "#{path}/collections.yml",
      YAML.dump([
        {
          'id' => SecureRandom.random_number(1_000_000_000),
          'title' => "Collection #{dump_key}",
          'owner_user_id' => user_id
        }
      ])
    )

    uploads_path = File.join(path, 'public', 'uploads')
    ['document_set', 'user', 'work'].each do |dir|
      FileUtils.mkdir_p(File.join(uploads_path, dir))
    end
  end

  around do |example|
    ActiveRecord::Base.transaction do
      example.run

      raise ActiveRecord::Rollback
    end
  end

  it 'imports dumps' do
    puts result.full_errors
    expect(result.success?).to be_truthy

    expect(user.reload).not_to be_nil
    expect(collection.reload).not_to be_nil
  end
end
