require 'spec_helper'
require 'rake'

describe 'fromthepage:remediator:report_orphan_subject_links' do
  before(:all) do
    Rake.application = Rake::Application.new
    Rails.application.load_tasks
  end

  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner, title: 'Letters from Home') }

  def report_rows
    Rake::Task['fromthepage:remediator:report_orphan_subject_links'].reenable

    Dir.mktmpdir do |directory|
      path = File.join(directory, 'orphans.csv')
      Rake::Task['fromthepage:remediator:report_orphan_subject_links'].invoke(collection.id, path)
      return CSV.read(path, headers: true)
    end
  end

  it 'reports the page, transcribe URL, orphan link, and subject identified by title history' do
    current_article = create(:article, collection: collection, title: 'Jane Smith')
    create(:article_version, article: current_article, user: owner, title: 'Jane Doe')
    page = create(:page, work: work, title: 'Page 12')
    page.update_column(
      :xml_text,
      "<page><p><link target_id='987654' target_title='Jane Doe'>Jane</link></p></page>"
    )

    row = report_rows.first

    expect(row['Page ID']).to eq(page.id.to_s)
    expect(row['Page Title']).to eq('Page 12')
    expect(row['Work ID']).to eq(work.id.to_s)
    expect(row['Work Title']).to eq('Letters from Home')
    expect(row['Transcribe URL']).to eq(
      Rails.application.routes.url_helpers.collection_transcribe_page_url(owner, collection, work, page)
    )
    expect(row['Orphan Subject ID']).to eq('987654')
    expect(row['Orphan Subject Title']).to eq('Jane Doe')
    expect(row['Suggested Subject ID']).to eq(current_article.id.to_s)
    expect(row['Suggested Subject Title']).to eq('Jane Smith')
    expect(row['Suggestion Source']).to eq('Article title history')
  end

  it 'falls back to a current same-title subject and excludes valid links' do
    replacement = create(:article, collection: collection, title: 'Jane Doe')
    valid = create(:article, collection: collection, title: 'John Doe')
    page = create(:page, work: work)
    page.update_column(
      :xml_text,
      <<~XML
        <page><p>
          <link target_id='987654' target_title='Jane Doe'>Jane</link>
          <link target_id='#{valid.id}' target_title='John Doe'>John</link>
        </p></page>
      XML
    )

    rows = report_rows

    expect(rows.size).to eq(1)
    expect(rows.first['Suggested Subject ID']).to eq(replacement.id.to_s)
    expect(rows.first['Suggestion Source']).to eq('Current article with matching title')
  end

  it 'does not change pages or subjects while producing the report' do
    page = create(:page, work: work)
    xml_text = "<page><p><link target_id='987654' target_title='Missing'>Missing</link></p></page>"
    page.update_column(:xml_text, xml_text)
    article_ids = collection.articles.ids

    report_rows

    expect(page.reload.xml_text).to eq(xml_text)
    expect(collection.articles.reload.ids).to eq(article_ids)
  end
end
