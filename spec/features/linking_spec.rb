# frozen_string_literal: true

require 'spec_helper'

describe 'subject linking' do
  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    login_as(user, scope: :user)
  end

  after do |example|
    if example.metadata[:js]
      category_ids = collection.category_ids
      ArticlesCategory.where(category_id: category_ids).delete_all
      collection.categories.destroy_all
      collection.destroy!
      [user, owner].each(&:destroy!)
    else
      DatabaseCleaner.clean
    end
  end

  let(:user) { create(:unique_user) }
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: [], subjects_disabled: false) }
  let(:work) { create(:work, collection: collection, owner: owner) }
  let!(:work_pages) do
    4.times.map do |index|
      create(:page, work: work, position: index + 1, title: "Linking Page #{index + 1}")
    end
  end
  let(:people_category) { collection.categories.find_by!(title: 'People') }
  let(:places_category) { collection.categories.find_by!(title: 'Places') }
  let(:texas_article) { create_categorized_article('Texas', places_category) }

  it 'looks at subjects in a collection', js: true do
    create_categorized_article('Ada Lovelace', people_category)
    texas_article

    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content('Categories')

    collection.categories.each do |category|
      within 'form.category-tree' do
        expect(page).to have_content(category.title)
        find('a.tree-item', text: category.title, exact_text: false).click
      end

      category.articles.each do |article|
        expect(page).to have_content(article.title, wait: 5)
      end
    end
  end

  it "edits a subject's description" do
    article = create(:article, collection: collection, title: 'Subject without a description')

    visit collection_article_show_path(owner, collection, article)
    expect(page).to have_content('Description')
    page.find('.tabs').click_link('Settings')

    expect(page).to have_content('Description')
    expect(page).not_to have_content('Related Subjects')
    expect(page).not_to have_content('Delete Subject')
    page.fill_in 'article_source_text', with: 'This is the text about my article.'
    click_button('Save Changes')

    expect(page).to have_content('This is the text about my article.')
    expect(article.article_versions.count).to be >= 1
  end

  it 'conditionally displays GIS fields on subject' do
    article = create_categorized_article('GIS Subject', places_category)

    visit collection_article_show_path(owner, collection, article)
    page.find('.tabs').click_link('Settings')
    expect(page).not_to have_content('Latitude')

    places_category.update!(gis_enabled: true)
    visit collection_article_show_path(owner, collection, article)
    page.find('.tabs').click_link('Settings')

    expect(page).to have_content('Latitude')
  end

  it 'deletes a subject', js: true do
    article = create_categorized_article('Testing', places_category)
    logout(:user)
    login_as(owner, scope: :user)

    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Subjects')
    click_link(article.title)
    page.find('.tabs').click_link('Settings')
    accept_confirm { click_link('Delete Subject') }

    expect(page).to have_content(places_category.title)
    page.find('a.tree-item', text: places_category.title).click
    expect(page).to have_content('There are no subjects for the category selected')
  end

  it 'links a categorized subject' do
    texas_article
    test_page = work_pages.last
    transcribe(test_page, '[[Texas]]')

    page.click_link('Overview')
    expect(page).to have_content('Transcription')
    expect(page).to have_content('Texas')
    expect(subject_link_count(test_page, 'transcription')).to eq(1)

    page.find('.tabs').click_link('Transcribe')
    fill_in_editor_field '[[Texas]]'
    find('#save_button_top').click
    page.click_link('Overview')

    expect(page).to have_content('Texas')
    expect(subject_link_count(test_page, 'transcription')).to eq(1)

    page.find('a', text: 'Texas').click
    expect(page).to have_content('Related Subjects')
    expect(page).to have_content('Texas')
    page.find('.tabs').click_link('Versions')
    expect(texas_article.article_versions.count).to be >= 1
    expect(page).to have_content('1 revision')
  end

  it 'enters a bad link with no closing braces' do
    test_page = work_pages.third
    open_transcription(test_page)
    fill_in_editor_field '[[Texas'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Wrong number of closing braces')

    fill_in_editor_field '[[Texas]]'
    find('#save_button_top').click
    page.click_link('Overview')
    expect(page).to have_content('Transcription')
    expect(page).to have_content('Texas')
  end

  it 'detects the current link start even with unmatched brackets elsewhere', js: true do
    open_transcription(work_pages.third)
    page.execute_script("myCodeMirror.setValue('Broken close ]] earlier\\n[[Tex');")
    page.execute_script('myCodeMirror.setCursor({line: 1, ch: 5});')

    link_start_at = page.evaluate_script('findLinkStartAtCursor(myCodeMirror, myCodeMirror.getCursor())')
    expect(link_start_at).to eq(2)
  end

  it 'enters bad links with missing text' do
    test_page = work_pages.fourth
    open_transcription(test_page)

    fill_in_editor_field '[[ ]]'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Blank tag')

    fill_in_editor_field '[[|Texas]]'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Blank subject')

    fill_in_editor_field '[[Texas| ]]'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Blank text')

    fill_in_editor_field '[[Texas]]'
    find('#save_button_top').click
    page.click_link('Overview')
    expect(page).to have_content('Transcription')
    expect(page).to have_content('Texas')
  end

  it 'enters a bad link with a single starting bracket' do
    test_page = work_pages.third
    open_transcription(test_page)
    fill_in_editor_field '[[Texas[?]]'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Unclosed bracket')

    fill_in_editor_field '[[Texas]]'
    find('#save_button_top').click
    expect(page).to have_content('Transcription')
    expect(page).to have_content('Texas')
  end

  it 'enters a bad link with triple brackets' do
    test_page = work_pages.third
    open_transcription(test_page)
    fill_in_editor_field '[[[Texas]]]'
    find('#save_button_top').click
    expect(page).to have_content('Subject Linking Error: Tags should be created using 2 brackets, not 3')

    fill_in_editor_field '[[Texas]]'
    find('#save_button_top').click
    expect(page).to have_content('Transcription')
    expect(page).to have_content('Texas')
  end

  it 'creates a link that includes quotes' do
    open_transcription(work_pages.third)
    fill_in_editor_field '[["Houston"]]'
    find('#save_button_top').click

    expect(page).to have_content('Houston')
  end

  it 'links subjects on a translation' do
    texas_article
    translate_work = create(:work, collection: collection, owner: owner, supports_translation: true)
    test_page = create(:page, work: translate_work)
    open_translation(test_page)
    fill_in_editor_field '[[Texas]]'
    click_button('Save Changes')
    page.click_link('Overview')
    page.click_link('Show Translation')

    expect(page).to have_content('Texas')
    expect(subject_link_count(test_page, 'translation')).to eq(1)

    page.find('.tabs').click_link('Translate')
    fill_in_editor_field '[[Texas]]'
    click_button('Save Changes')
    page.click_link('Overview')
    page.click_link('Show Translation')

    expect(page).to have_content('Texas')
    expect(subject_link_count(test_page, 'translation')).to eq(1)
  end

  it 'tests autolinking in transcription' do
    texas_article
    link_page = work_pages.first
    create(:article, collection: collection, title: 'John Samuel Smith')
    samuel_article = create(:article, collection: collection, title: 'Samuel Jones')
    create(:page_article_link, page: work_pages.second, article: samuel_article, display_text: 'Samuel')
    link_page.update!(source_text: '[[John Samuel Smith]] Mrs. Davis')

    open_transcription(link_page)
    expect(page).to have_content('[[John Samuel Smith]]')
    expect(page).to have_content('Mrs. Davis')
    click_button('Autolink', match: :first)
    expect(page).not_to have_content('[[John [[Samuel Jones|Samuel]] Smith]]')
    expect(page).not_to have_content('[[Mrs.]]')
    expect(page).to have_content('Mrs. Davis')

    fill_in_editor_field 'Austin'
    click_button('Autolink', match: :first)
    expect(page).not_to have_content('[[Austin]]')

    fill_in_editor_field 'Texas'
    click_button('Autolink', match: :first)
    expect(page).to have_content('[[Texas]]')
  end

  it 'tests autolinking in translation' do
    texas_article
    translate_work = create(:work, collection: collection, owner: owner, supports_translation: true)
    test_page = create(:page, work: translate_work)
    open_translation(test_page)

    fill_in_editor_field 'Austin'
    click_button('Autolink')
    expect(page).not_to have_content('[[Austin]]')

    fill_in_editor_field 'Texas'
    click_button('Autolink')
    expect(page).to have_content('[[Texas]]')
  end

  it 'checks the number of subject links', js: true do
    link_page = work_pages.last
    transcribe(link_page, '[[Ada Lovelace]] [[Ada Lovelace]]')

    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Subjects')
    expect(page).to have_content('Ada Lovelace')
    click_link('Ada Lovelace')
    expect(page.find('.article-links').first('li')).to have_content('Ada Lovelace')
    expect(page.find('.article-links')).to have_selector('li', count: 2)
    expect(page.find('.article-links')).not_to have_selector('li', count: 1)
  end

  def create_categorized_article(title, category)
    article = create(:article, collection: collection, title: title)
    article.categories << category
    article
  end

  def open_transcription(test_page)
    visit collection_display_page_path(owner, collection, test_page.work, test_page)
    page.find('.tabs').click_link('Transcribe')
  end

  def transcribe(test_page, text)
    open_transcription(test_page)
    fill_in_editor_field text
    find('#save_button_top').click
  end

  def open_translation(test_page)
    visit collection_display_page_path(owner, collection, test_page.work, test_page)
    page.find('.tabs').click_link('Translate')
  end

  def subject_link_count(test_page, text_type)
    PageArticleLink.where(page: test_page, text_type: text_type).count
  end
end
