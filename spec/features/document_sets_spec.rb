# frozen_string_literal: true

require 'spec_helper'

describe 'document sets' do
  let(:owner) { create(:unique_user, :owner) }
  let(:user) { create(:unique_user) }
  let(:rest_user) { create(:unique_user) }
  let(:collection) do
    create(:collection, :docset_enabled, owner_user_id: owner.id, works: [], hide_completed: false)
  end
  let(:works) do
    Array.new(4) do
      create(:work, :with_pages, collection: collection, owner: owner, supports_translation: true)
    end
  end
  let(:document_set) do
    create(:document_set, :public, collection: collection, owner: owner, works: works.first(2))
  end
  let(:private_set) do
    create(:document_set, :private, collection: collection, owner: owner, works: [works.third])
  end
  let(:other_private_set) do
    create(:document_set, :private, collection: collection, owner: owner, works: [works.fourth])
  end
  let(:document_sets) { [document_set, private_set, other_private_set] }
  let(:category) { collection.categories.first }
  let(:article) { create(:article, collection: collection, title: 'Document Set Subject') }
  let(:outside_article) { create(:article, collection: collection, title: 'Collection-only Subject') }

  before do
    works
    collection.reload
    document_sets
    article.categories << category
    outside_article.categories << category
    Page.find(works.first.pages.first.id).update!(source_text: "[[#{article.title}]]")
    Page.find(works.third.pages.first.id).update!(source_text: "[[#{article.title}]]")
    Page.find(works.third.pages.second.id).update!(source_text: "[[#{outside_article.title}]]")
    user.notification.update!(add_as_collaborator: true)
    rest_user.notification.update!(add_as_collaborator: false)
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
    ArticlesCategory.where(article_id: collection.article_ids).delete_all
    collection.categories.destroy_all
    collection.document_sets.each do |set|
      DocumentSetWork.where(document_set_id: set.id).delete_all
      set.destroy!
    end
    collection.destroy!
    rest_user.destroy!
    user.destroy!
    owner.destroy!
  end

  it 'edits a document set (start at collection level)', js: true do
    login_as(owner, scope: :user)
    visit dashboard_owner_path
    page.find('.maincol').find('a', text: collection.title).click
    page.find('.tabs').click_link('Sets')
    expect(page).to have_content("Document Sets for #{collection.title}")
    within(page.find('#sets')) do
      within(page.find('tr', text: document_sets.first.title)) do
        page.find('a', text: 'Edit').click
      end
    end
    page.find('#document_set_title').set('')
    page.fill_in 'document_set_title', with: 'Edited Test Document Set 1'
    script = "$('#collection-settings-save').click()"
    page.execute_script(script)
    expect(page).to have_content('Document set has been saved')
    edited_set = document_sets.first.reload
    expect(edited_set.title).to eq 'Edited Test Document Set 1'
    expect(page.find('h1')).to have_content(edited_set.title)

    doc_set = edited_set
    work_ids = doc_set.work_ids

    page.find('.side-tabs').click_link('Manage Works')
    # Set all checkboxes off
    page.all('input[type="checkbox"].works', visible: false).each do |checkbox|
      checkbox.set(false)
    end

    # Click select all
    page.find('input[type="checkbox"][data-select-all="works"]', visible: false).check
    expect(page.find('input[type="checkbox"][data-select-all="works"]', visible: false)).to be_checked

    # Expect all checkboxes are true
    page.all('input[type="checkbox"].works', visible: false).each do |checkbox|
      expect(checkbox).to be_checked
    end

    work_ids += doc_set.work_ids

    doc_set.work_ids = []
    doc_set.save!

    doc_set.work_ids = work_ids.uniq
    doc_set.save!
  end

  it 'makes a document set private', js: true do
    login_as(owner, scope: :user)
    # create an additional document set to make private
    visit document_sets_path(collection_id: collection)
    page.find('.button', text: 'Create a Document Set').click
    page.fill_in 'document_set_title', with: 'Test Document Set 3'
    page.find_button('Create Document Set').click
    expect(page).to have_selector('h1', text: 'Test Document Set 3')
    created_set = DocumentSet.find_by!(title: 'Test Document Set 3', collection: collection)
    expect(page.current_path).to eq collection_settings_path(owner, created_set)
    page.find('.side-tabs').click_link('Privacy & Access')
    expect(page.find('h1')).to have_content('Test Document Set 3')
    expect(created_set.reload.is_public).to be true
    # make the set private
    page.choose('document_set_visibility_private')
    expect(page).to have_content('Document set has been saved')
    expect(created_set.reload.is_public).to be false
    expect(page).to have_content('Document set collaborators')
    # manually assign works until have the jqery test set
    id = collection.works.third.id
    created_set.work_ids = id
    created_set.save!
    expect(created_set.work_ids).to include collection.works.third.id
  end

  it "views document sets - regular user" do
    # need to restrict collection to test user view
    collection.restricted = true
    collection.save!
    # user with no privileges first
    login_as(user, scope: :user)
    visit dashboard_path
    [collection].each do |c|
      unless c.restricted
        expect(page).to have_content(c.title)
      else
        expect(page.find('.maincol')).not_to have_content(c.title)
      end
    end
    document_sets.each do |set|
      if set.is_public
        expect(page).to have_content(set.title)
      elsif !set.is_public
        expect(page).not_to have_content(set.title)
      end
    end
    # check to view public document set
    page.find('.maincol').find('a', text: document_set.title).click
    expect(page).to have_content("Overview")
    expect(page).to have_content(collection.works.first.title)
    expect(page).to have_content(collection.works.second.title)
    expect(page).not_to have_content(collection.works.last.title)
    expect(page).to have_content(document_set.works.first.title)
    page.find('.tabs').click_link('Statistics')
    expect(page).to have_content(document_set.title)
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/statistics"
    expect(page).to have_content("Last 7 Days Statistics")
    page.find('.tabs').click_link('Overview')
    page.find('.collection-work_title', text: document_set.works.first.title).click_link
    expect(page).to have_content(document_set.works.first.title)
    document_page = document_set.works.first.pages.first
    page.find('.work-page_title', text: document_page.title).click_link(document_page.title)
    expect(page.current_path).not_to eq collections_list_path
    expect(page.find('h1')).to have_content(document_page.title)
    # can a restricted user access a private doc set through a link
    visit collection_path(owner, private_set)
    expect(page.current_path).to eq user_profile_path(owner)
    expect(page.find('h1')).not_to have_content(private_set.title)
    # can a restricted user see a work from a private collection through a link
    visit collection_read_work_path(owner, collection, collection.works.last)
    expect(page.current_path).to eq user_profile_path(owner)
    expect(page.find('h1')).not_to have_content(collection.works.last.title)
  end

  it 'adds a collaborator' do
    ActionMailer::Base.deliveries.clear
    login_as(owner, scope: :user)
    visit collection_path(private_set.owner, private_set)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Privacy & Access')
    page.click_link 'Edit Collaborators'
    # this user should not receive an email (notifications off)
    select(rest_user.name_with_identifier, from: 'collaborator_id')
    page.find('.add_collaborator').click
    expect(ActionMailer::Base.deliveries).to be_empty
    # this user should receive an email
    select(user.name_with_identifier, from: 'collaborator_id')
    page.find('.add_collaborator').click
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.to).to include user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{private_set.title}"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match('added you as a collaborator')
  end

  it 'tests a collaborator' do
    private_set.collaborators << user
    login_as(user, scope: :user)
    visit dashboard_path
    [collection].each do |c|
      unless c.restricted
        expect(page).to have_content(c.title)
      else
        expect(page.find('.maincol')).not_to have_content(c.title)
      end
    end
    document_sets.each do |set|
      if set.is_public
        expect(page).to have_content(set.title)
      elsif !set.is_public
        if set.collaborators.include?(user)
          expect(page).to have_content(set.title)
        else
          expect(page).not_to have_content(set.title)
        end
      end
    end
    # check collaborator access to private doc set
    visit collection_path(owner, private_set)
    expect(page.find('h1')).to have_content(private_set.title)
    expect(page.find('.maincol')).to have_content(private_set.works.first.title)
    # check collaborator access through a link
    visit collection_read_work_path(owner, private_set, private_set.works.first)
    expect(page.find('h1')).to have_content(private_set.works.first.title)
    # check that the collaborator can't access other private doc set
    visit collection_read_work_path(owner, other_private_set, other_private_set.works.first)
    expect(page.current_path).to eq user_profile_path(owner)
    expect(page.find('h1')).not_to have_content(other_private_set.works.first.title)
  end

  it "checks notes on a public doc set/private collection", js: true do
    collection.update!(restricted: true)
    login_as(user, scope: :user)
    visit collection_transcribe_page_path(document_set.owner, document_set, document_set.works.first, document_set.works.first.pages.first)
    fill_in 'Write a new note or ask a question...', with: "Test private note"
    find('#save_note_button').click
    expect(page).to have_content "Note has been created"
    note = Note.last
    visit collection_path(document_set.owner, document_set)
    page.find('a', text: "Test private note").click
    expect(page.current_path).to eq collection_display_page_path(document_set.owner, document_set, document_set.works.first, document_set.works.first.pages.first)
    page.find('.user-bubble_content', text: "Test private note")

    # test activity stream for set
    visit collection_path(document_set.owner, document_set)
    expect(page).to have_content "Test private note"
    find("#show-more-deeds").click
    expect(page).to have_content "Test private note"
    page.find('a', text: document_set.works.first.pages.first.title).click
    expect(page.current_path).to eq collection_display_page_path(document_set.owner, document_set, document_set.works.first, document_set.works.first.pages.first)


    # test activity stream for collection
    login_as(owner, scope: :user)
    visit collection_path(document_set.owner, document_set.collection)
    expect(page).to have_content "Test private note"
    find("#show-more-deeds").click
    expect(page).to have_content "Test private note"
    page.find('a', text: document_set.works.first.pages.first.title).click
    expect(page.current_path).to eq collection_display_page_path(document_set.owner, document_set.collection, document_set.works.first, document_set.works.first.pages.first)
  end

  it "looks at document sets owner tabs", js: true do
    login_as(owner, scope: :user)
    work = document_set.works.first
    visit "/#{owner.slug}/#{document_set.slug}"
    page.find('.tabs').click_link("Settings")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/settings"
    expect(page.find('h1')).to have_content(document_set.title)
    expect(page).to have_content("Title")
    expect(page).not_to have_content("Collection Owners")
    visit "/#{owner.slug}/#{document_set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.tabs').click_link("Pages")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/pages"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.tabs').click_link("Settings")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/edit"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.side-tabs').click_link('Task Configuration')
    work.update!(supports_translation: false)
    visit "/#{owner.slug}/#{document_set.slug}/#{work.slug}/edit/tasks"
    page.check('work_supports_translation')
    expect(page).to have_content('Work updated successfully')
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/edit/tasks"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
  end

  it "checks document set breadcrumbs - collection" do
    login_as(user, scope: :user)
    visit dashboard_path
    page.find('.maincol').find('a', text: document_set.title).click
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}"
    page.find('.tabs').click_link("Statistics")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/statistics"
    expect(page.find('h1')).to have_content(document_set.title)
  end

  it "checks document set breadcrumbs - subjects", js: true do
    login_as(user, scope: :user)

    visit dashboard_path
    page.find('.maincol').find('a', text: document_set.title).click
    page.find('.tabs').click_link("Subjects")
    expect(page.find('.category-tree')).to have_content(document_set.categories.first.title, wait: 5)
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/subjects"
    expect(page.find('h1')).to have_content(document_set.title)
    # expect to have only article from document sets
    expect(page).to have_selector('.category-article', text: article.title, wait: 5)
    expect(page).not_to have_selector('.category-article', text: outside_article.title)
    page.find('a', text: article.title).click
    expect(page).to have_selector('.breadcrumbs')
    expect(page).to have_selector('a', text: document_set.title)

    page.find('.tabs').click_link("Settings")
    expect(page).to have_selector('.breadcrumbs')
    expect(page).to have_selector('a', text: document_set.title)

    click_button 'Autolink'
    expect(page).to have_selector('.breadcrumbs')
    expect(page).to have_selector('a', text: document_set.title)

    click_button('Save Changes')
    expect(page).to have_selector('.breadcrumbs')
    expect(page).to have_selector('a', text: document_set.title)

    page.find('.tabs').click_link("Versions")
    expect(page).to have_selector('.breadcrumbs')
    expect(page).to have_selector('a', text: document_set.title)
  end

  it 'checks document set subject tabs' do
    login_as(owner, scope: :user)
    visit collection_article_show_path(document_set.owner, document_set, article.id)
    expect(page).to have_content('Description')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('a', text: 'Edit the description in the settings tab.').click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page).to have_content('Title')
    page.find('.tabs').click_link('Overview')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.sidecol')).to have_content(article.categories.first.title)
    # click_button("Search All Pages")
    # expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    # expect(page).to have_content("Search for")
    # #return to overview
    # visit collection_article_show_path(document_set.owner, document_set, article.id)
    # click_button("Search Unlinked Pages")
    # expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    # expect(page).to have_content("Search for")
    page.find('a', text: "Show pages that mention #{article.title} in all works").click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    set_pages = article.pages.where(work_id: document_set.works.ids)
    col_pages = article.pages.where.not(work_id: document_set.works.ids)
    set_pages.each do |p|
      expect(page.find('.maincol')).to have_content(p.work.title)
      expect(page.find('.maincol')).to have_content(p.title)
    end
    col_pages.each do |p|
      expect(page.find('.maincol')).not_to have_content(p.work.title)
      expect(page.find('.maincol')).not_to have_content(p.title)
    end
    visit collection_article_show_path(document_set.owner, document_set, article.id)
    page.find('.article-links').find('a', text: set_pages.first.title).click
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    visit collection_display_page_path(document_set.owner, document_set, set_pages.first.work, set_pages.first)
    page.find('a', text: article.title).click
    expect(page.current_path).to eq collection_article_show_path(document_set.owner, document_set, article.id)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
  end

  it 'checks document set breadcrumbs - work' do
    login_as(user, scope: :user)
    work = document_set.works.first
    document_page = work.pages.first
    visit dashboard_path
    page.find('.maincol').find('a', text: document_set.title).click
    page.find('.collection-work_title', text: work.title).click_link
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page).not_to have_selector('a', text: 'Pages That Need Review')
    expect(page).not_to have_selector('a', text: 'Translations That Need Review')

    original_page_status = document_page.status
    document_page.update_columns(status: 'review')
    visit dashboard_path
    page.find('.maincol').find('a', text: document_set.title).click
    page.find('.collection-work_title', text: work.title).click_link
    click_button('Pages That Need Review')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page).not_to have_content('No pages found')
    document_page.update!(status: original_page_status)

    original_page_translation_status = document_page.translation_status
    document_page.update_columns(translation_status: 'review')
    visit dashboard_path
    page.find('.maincol').find('a', text: document_set.title).click
    page.find('.collection-work_title', text: work.title).click_link
    click_button('Translations That Need Review')
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page).not_to have_content('No pages found')
    document_page.update!(translation_status: original_page_translation_status)

    page.find('.tabs').click_link('About')
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/about"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.tabs').click_link('Contents')
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/contents"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.tabs').click_link('Help')
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/help"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    click_link document_set.title
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}"
  end

  it "checks document set breadcrumbs - page level" do
    login_as(user, scope: :user)
    work = document_set.works.first
    document_page = work.pages.first

    # make sure it's right if you click on the page from the work
    visit "/#{owner.slug}/#{document_set.slug}/#{work.slug}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    page.find('.work-page_title', text: document_page.title).click_link
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)

    # so that it doesn't matter if the page has been transcribed, go directly to overview
    visit "/#{owner.slug}/#{document_set.slug}/#{work.slug}/display/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)

    # Transcribe Tab
    page.find('.tabs').click_link("Transcribe")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/transcribe/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    fill_in_editor_field "Document set breadcrumbs\n\n#{document_page.source_text}"
    find('#save_button_top').click

    # Overview Tab
    page.click_link("Overview")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/display/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    expect(page).to have_content("Transcription")

    # Translate Tab
    page.find('.tabs').click_link("Translate")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/translate/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    page.fill_in 'page_source_translation', with: "Document set breadcrumbs - translation"
    click_button('Save Changes')

    # Overview Tab
    page.click_link("Overview")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/display/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)
    expect(page).to have_content("Translation")

    # Versions Tab
    page.find('.tabs').click_link("Versions")
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}/versions/#{document_page.id}"
    expect(page.find('.breadcrumbs')).to have_selector('a', text: document_set.title)
    expect(page.find('.breadcrumbs')).to have_selector('a', text: work.title)

    click_link(work.title)
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}/#{work.slug}"

    click_link document_set.title
    expect(page.current_path).to eq "/#{owner.slug}/#{document_set.slug}"
  end

  it 'checks doc set needs transcription/review buttons' do
    login_as(user, scope: :user)
    visit collection_path(document_set.owner, document_set)
    expect(page).to have_selector('h1', text: document_set.title)
    expect(page).to have_content('Works')
    expect(page).to have_selector('a', text: 'Pages That Need Transcription')
    expect(page).not_to have_selector('a', text: 'Pages That Need Review')
  end

  it "disables document sets", js: true do
    # Ensure document sets are enabled initially
    collection.update!(supports_document_sets: true)

    login_as(owner, scope: :user)
    visit edit_collection_path(collection.owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    page.uncheck('Enable document sets')
    expect(page.find_link("Edit Sets")).to match_css('[disabled]')
    expect(Collection.find_by(id: collection.id).supports_document_sets).to be false
  end

  it "enables document sets", js: true do
    # Ensure document sets are disabled initially
    collection.update!(supports_document_sets: false)

    login_as(owner, scope: :user)
    visit edit_collection_path(collection.owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    page.check("Enable document sets")
    expect(page).to have_content('Collection has been updated')
    expect(page.find_link("Edit Sets")).not_to match_css('[disabled]')
    visit document_sets_path(collection_id: collection)
    expect(page.current_path).to eq document_sets_path
    expect(collection.reload.supports_document_sets).to be true
  end

  it 'edits a document set slug', js: true do
    login_as(owner, scope: :user)
    slug = "new-#{document_set.slug}"
    visit "/#{owner.slug}/#{document_set.slug}"
    expect(page).to have_selector('h1', text: document_set.title)
    document_set.works.each do |w|
      expect(page).to have_content w.title
    end
    page.find('.tabs').click_link('Settings')
    expect(page.find('h1')).to have_content document_set.title
    expect(page).to have_field('document_set[slug]', with: document_set.slug)
    page.fill_in 'document_set_slug', with: "new-#{document_set.slug}"
    script = "$('#collection-settings-save').click()"
    page.execute_script(script)
    expect(page).to have_content('Document set has been saved', wait: 5)
    expect(page.find('h1')).to have_content document_set.title
    expect(DocumentSet.find_by(id: document_set.id).slug).to eq "#{slug}"
    # check new path
    visit "/#{owner.slug}/#{slug}"
    expect(page).to have_selector('h1', text: document_set.title)
    document_set.works.each do |w|
      expect(page).to have_content w.title
    end
    # check the old path
    # (this variable is stored at the beginning of the test, so it's the original)
    visit "/#{owner.slug}/#{document_set.slug}"
    expect(page).to have_selector('h1', text: document_set.title)
    document_set.works.each do |w|
      expect(page).to have_content w.title
    end
    # blank out doc set slug
    visit "/#{owner.slug}/#{document_set.slug}"
    expect(page).to have_selector('h1', text: document_set.title)
    page.find('.tabs').click_link('Settings')
    expect(page.find('h1')).to have_content document_set.title
    new_slug = document_set.reload.slug
    expect(page).to have_field('document_set[slug]', with: new_slug)
    page.fill_in 'document_set_slug', with: ""
    script = "$('#collection-settings-save').click()"
    page.execute_script(script)
    expect(page).to have_content('Document set has been saved')
    docset = DocumentSet.find_by(id: document_set.id)
    # note - the document set title was changed so the slug is slightly different
    expect(docset.slug).to eq docset.title.parameterize
  end


end
