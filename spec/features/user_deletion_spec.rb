require 'spec_helper'

describe 'User deletion' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:admin) { create(:unique_user, :admin) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:work_page) { create(:page, work: work) }
  let!(:article) { create(:article, collection: collection) }

  # A user who will perform actions and then be deleted
  let!(:doomed_user) { create(:unique_user) }

  before :each do
    # Leave a note as the doomed user
    login_as(doomed_user, scope: :user)
    visit collection_read_work_path(work.collection.owner, work.collection, work)
    page.find('.work-page_title', text: work_page.title).click_link(work_page.title)
    fill_in 'note_body', with: 'Test private note'
    find('#save_note_button').click

    # Transcribe the page as the doomed user
    visit "/display/display_page?page_id=#{work_page.id}"
    page.find('.tabs').click_link('Transcribe')
    fill_in_editor_field '[[Places|Texas]]'
    find('#save_button_top').click

    # Edit the article as the doomed user
    visit "/article/show?article_id=#{article.id}"
    click_link('Settings')
    page.fill_in 'article_source_text', with: 'This is more text about my article.'
    click_button('Save Changes')

    # Delete the user as admin
    login_as(admin, scope: :user)
    visit url_for(action: 'delete_user', controller: 'admin', user_id: doomed_user.id)
  end

  it 'does not break collection home' do
    visit collection_path(collection.owner, collection)
    expect(page).to have_selector('h1', text: collection.title)
  end

  it 'does not break deed list' do
    visit url_for(action: 'list', controller: 'deed')
    expect(page.status_code).to eq(200)
  end

  it 'does not break page versions' do
    login_as(admin, scope: :user)
    visit "/display/display_page?page_id=#{work_page.id}"
    click_link('Versions')
    expect(page.status_code).to eq(200)
  end

  it 'does not break page notes' do
    visit "/display/display_page?page_id=#{work_page.id}"
    expect(page.status_code).to eq(200)
  end

  it 'does not break article versions' do
    visit "/article/show?article_id=#{article.id}"
    click_link('Versions')
    expect(page.status_code).to eq(200)
  end
end
