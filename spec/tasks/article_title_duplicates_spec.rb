require 'spec_helper'
require 'rake'

describe 'Article title duplicate rake tasks' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  let!(:collection) { create(:collection, works: []) }
  let!(:canonical_article) { create(:article, title: 'Duplicate Subject', collection: collection) }
  let!(:duplicate_article) do
    article = build(:article, title: 'duplicate subject', collection: collection)
    article.save!(validate: false)
    article
  end
  let(:output_file) { Rails.root.join('tmp', "duplicate_article_titles_#{SecureRandom.hex}.csv") }

  after do
    FileUtils.rm_f(output_file)
  end

  it 'reports duplicates without modifying either article' do
    Rake::Task['fromthepage:title_duplicates:report'].reenable
    Rake::Task['fromthepage:title_duplicates:report'].invoke(output_file)

    rows = CSV.read(output_file, headers: true)
    expect(rows.first.to_h).to include(
      'collection_id' => collection.id.to_s,
      'canonical_article_id' => canonical_article.id.to_s,
      'duplicate_article_id' => duplicate_article.id.to_s
    )
    expect(duplicate_article.reload.title).to eq('duplicate subject')
  end

  it 'writes the audit report before reconciling duplicate titles' do
    Rake::Task['fromthepage:title_duplicates:reconcile'].reenable
    Rake::Task['fromthepage:title_duplicates:reconcile'].invoke(output_file)

    expect(File).to exist(output_file)
    expect(duplicate_article.reload.title).to eq("duplicate subject [duplicate #{duplicate_article.id}]")
    expect(canonical_article.reload.title).to eq('Duplicate Subject')
  end
end
