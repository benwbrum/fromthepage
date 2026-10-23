# frozen_string_literal: true

require 'spec_helper'

FIELD_XML = <<EOF
<?xml version='1.0' encoding='UTF-8'?>
      <page>
        <p><span class='field__label'>Last Name: </span>Mitchell</p><p><span class='field__label'>First Name: </span>John</p><p><span class='field__label'>Middle Name: </span></p><p><span class='field__label'>Suffix or Title: </span></p><p><span class='field__label'>Home Town: </span>Pinson</p><p><span class='field__label'>Home County: </span>Jefferson</p><p><span class='field__label'>Home State: </span>Alabama</p><p><span class='field__label'>Race: </span>Caucasian</p><p><span class='field__label'>Gender: </span></p><p><span class='field__label'>Branch: </span>Army</p><p><span class='field__label'>Service Number: </span>14208593</p><p><span class='field__label'>See Also: </span></p><p><span class='field__label'>Notes: </span></p><p/>
      </page>
EOF


describe 'editor actions' do
  context 'model-backed editor actions' do
    let(:user) { create(:unique_user) }
    let(:collection) { create(:collection, owner_user_id: user.id, works: []) }
    let(:work) { create(:work, collection: collection, owner: user) }
    let(:page_fact) { create(:page, work: work) }

    before do
      DatabaseCleaner.start
      login_as(user, scope: :user)
    end

    after do
      DatabaseCleaner.clean
    end

    it "marks page blank" do
      visit "/display/display_page?page_id=#{page_fact.id}"
      expect(page).to have_content("This page is not transcribed")
      page.find('.tabs').click_link("Transcribe")
      page.find('#page_mark_blank').set(true)
      page.find('#save_button_top').click
      expect(page).to have_checked_field('page_mark_blank')
    end
    it "resets page status to nil if empty and not marked BLANK" do
      visit "/display/display_page?page_id=#{page_fact.id}"
      expect(page).to have_content("This page is not transcribed")
      page.find('.tabs').click_link("Transcribe")
      fill_in_editor_field("Content")
      page.find('#save_button_top').click

      expect(Page.find(page_fact.id).status_incomplete?).to be_truthy

      fill_in_editor_field("")
      page.find('#save_button_top').click

      expect(Page.find(page_fact.id).status_new?).to be_truthy
    end

    it "creates correct verbatim plaintext" do
      page_fact.source_text = "foo <strike>bar</strike> contin-\nued on next\nline"
      page_fact.save

      expect(page_fact.verbatim_transcription_plaintext).to eq("foo bar contin-\nued on next\nline\n\n\n")
    end

    it "creates correct search text" do
      page_fact.source_text = "foo <strike>bar</strike> contin-\nued on next\nline"
      page_fact.save

      expect(page_fact.search_text).to eq("foo bar continued on next line\n\n\n\n")
    end

    it "creates search text from fields" do
      page_fact.xml_text = FIELD_XML
      page_fact.save

      expect(page_fact.search_text).to match("Mitchell First")
    end
  end

  context 'browser editor actions' do
    let(:owner) { create(:unique_user, :owner) }
    let(:user) { create(:unique_user) }
    let(:rest_user) { create(:unique_user) }
    let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
    let(:work) do
      create(
        :work,
        collection: collection,
        owner: owner,
        supports_translation: true,
        description: 'Description'
      )
    end
    let(:work_pages) { create_list(:page, 5, work: work) }
    let(:work_page) { work_pages.first }
    let(:restricted_collection) { create(:collection, owner_user_id: owner.id, works: []) }
    let(:restricted_work) do
      create(:work, :restricted, collection: restricted_collection, owner: owner)
    end
    let(:restricted_page) { create(:page, work: restricted_work) }

    before do
      work_pages
      restricted_page
      collection.collaborators << user
      create(:deed, user: user, collection: collection, work: work)
      user.notification.update!(add_as_collaborator: true)
      rest_user.notification.update!(add_as_collaborator: false)
      ActionMailer::Base.deliveries.clear
      login_as(user, scope: :user)
    end

    after do
      ActionMailer::Base.deliveries.clear
      Flag.where(author_user_id: [user.id, rest_user.id]).destroy_all
      restricted_collection.categories.destroy_all
      collection.categories.destroy_all
      restricted_collection.destroy!
      collection.destroy!
      rest_user.destroy!
      user.destroy!
      owner.destroy!
    end

    it "checks that a guest does not see a Transcribe tab on a restricted work" do
      logout(:user)
      expect(restricted_work.restrict_scribes).to be true
      visit collection_read_work_path(restricted_work.owner, restricted_work.collection, restricted_work)
      page.find('.work-page_title', text: restricted_page.title).click_link
      expect(page.find('.tabs')).not_to have_content("Transcribe")
    end

    it "checks that a guest does see a Transcribe tab on an unrestricted work" do
      logout(:user)
      expect(work.restrict_scribes).to be false
      visit collection_read_work_path(work.owner, work.collection, work)
      page.find('.work-page_title', text: work.pages.first.title).click_link
      expect(page.find('.tabs')).to have_content("Transcribe")
    end

    it "checks that a restricted editor can't transcribe a work" do
      logout(:user)
      login_as(rest_user, scope: :user)
      visit collection_read_work_path(restricted_work.owner, restricted_work.collection, restricted_work)
      page.find('.work-page_title', text: restricted_page.title).click_link
      expect(page.find('.tabs')).not_to have_content("Transcribe")
    end

    it 'adds a user to a restricted work' do
      ActionMailer::Base.deliveries.clear
      logout(:user)
      login_as(owner, scope: :user)
      visit edit_collection_work_path(restricted_work.owner, restricted_work.collection, restricted_work)
      page.find('.side-tabs').click_link("Privacy & Access")
      page.click_link 'Edit Collaborators'
      # this user should not get an email
      select(rest_user.name_with_identifier, from: 'scribe_id')
      page.find('.add_scribe').click
      expect(ActionMailer::Base.deliveries).to be_empty
      # this user should get an email
      select(user.name_with_identifier, from: 'scribe_id')
      page.find('.add_scribe').click
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.first.to).to include user.email
      expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{restricted_work.title}"
      expect(ActionMailer::Base.deliveries.first.body.encoded).to match('added you as a collaborator')
    end

    it 'checks that an editor with permissions can see a restricted work' do
      restricted_work.scribes << user
      visit collection_read_work_path(restricted_work.owner, restricted_work.collection, restricted_work)
      page.find('.work-page_title', text: restricted_page.title).click_link
      expect(page.find('.tabs')).to have_content('Transcribe')
    end

    it 'removes a collaborator from a restricted work' do
      restricted_work.scribes << rest_user
      logout(:user)
      login_as(owner, scope: :user)
      visit edit_collection_work_path(restricted_work.owner, restricted_work.collection, restricted_work)
      page.find('.side-tabs').click_link("Privacy & Access")
      page.click_link 'Edit Collaborators'
      page.find('.user-label', text: rest_user.name_with_identifier).find('button.remove').click
      expect(page).not_to have_selector('.user-label', text: rest_user.name_with_identifier)
    end

    it "looks at a collection" do
      visit dashboard_watchlist_path
      first('h4', text: collection.title).click_link(collection.title)
      expect(page).to have_content("Works")
      expect(page).to have_content(work.title)
      expect(page).not_to have_content("Collection Footer")
      # check the tabs in the collection
      # Subjects
      page.find('.tabs').click_link("Subjects")
      expect(page).to have_content("People")
      expect(page).to have_content("Places")
      # Statistics
      page.find('.tabs').click_link("Statistics")
      expect(page).to have_content("Collaborators")
      # make sure we don't have the owner tabs
      expect(page.find('.tabs')).not_to have_content("Settings")
      expect(page.find('.tabs')).not_to have_content("Export")
      expect(page.find('.tabs')).not_to have_content("Collaborators")
    end

    it "looks at a work" do
      visit collection_path(collection.owner, collection)
      page.find('.collection-work_title', text: work.title).click_link
      expect(page).to have_content(work_page.title)
      # Check the tabs in the work
      # About
      page.find('.tabs').click_link("About")
      expect(page).to have_content(work.title)
      expect(page).to have_content("Description")
      # Help
      page.find('.tabs').click_link("Help")
      expect(page).to have_content("Transcribing")
      expect(page).to have_content("Linking Subjects")
      # Contents
      page.find('.tabs').click_link("Contents")
      expect(page).to have_content("Page Title")
      expect(page).to have_content(work.pages.last.title)
      within(page.find('tr', text: work.pages.last.title)) do
        page.find('a', text: 'Transcribe').click
      end
      expect(page).to have_content("Transcription Conventions")
      expect(page).to have_selector("textarea")
    end

    it "looks at pages" do
      visit collection_read_work_path(work.collection.owner, work.collection, work)
      expect(page).to have_content("please help transcribe this page")
      page.find('.work-page_title', text: work_page.title).click_link
      page.find('#page_source_text')
      expect(page).to have_button('Preview')
      expect(page).to have_content(work_page.title)
      expect(page).not_to have_content("Collection Footer")
      # Versions
      page.find('.tabs').click_link("Versions")
      expect(page).to have_content("revisions")
    end

    it "transcribes a page" do
      visit "/display/display_page?page_id=#{work_page.id}"
      expect(page).to have_content("This page is not transcribed")
      page.find('.tabs').click_link("Transcribe")
      expect(page).not_to have_content("Collection Footer")
      fill_in_editor_field "Test Preview"
      click_button('Preview', match: :first)
      expect(page).to have_content('Edit')
      expect(page).to have_content("Test Preview")
      click_button('Edit', match: :first)
      expect(page).to have_content('Preview')
      fill_in_editor_field "Test Transcription\n\n-\ndash test"
      find('#save_button_top').click
      page.click_link("Overview")
      expect(page).to have_content("Test Transcription")
      expect(page).to have_content("Facsimile")
    end
    it "translates a page" do
      visit "/display/display_page?page_id=#{work.pages.first.id}"
      page.find('.tabs').click_link("Translate")
      expect(page).not_to have_content("Collection Footer")
      fill_in_editor_field "Test Translation Preview"
      click_button('Preview')
      expect(page).to have_content('Edit')
      expect(page).to have_content("Test Translation Preview")
      click_button('Edit')
      expect(page).to have_content('Preview')
      fill_in_editor_field "Test Translation"
      click_button('Save Changes')
      expect(page).to have_content("Test Translation")
    end

    it "translation displays transcription text by default", js: true do
      work_page.update!(source_text: 'Transcription shown while translating')
      visit "/display/display_page?page_id=#{work.pages.first.id}"
      page.find('.tabs').click_link("Translate")
      expect(page).to_not have_selector('.page-imagescan')
      expect(page).to have_selector('.page-preview')
    end
    it "checks a plain user profile" do
      login_as(user, scope: :user)
      visit dashboard_path
      page.find('a', text: 'Your Profile').click
      expect(page).to have_content(user.display_name)
      expect(page).to have_content("Recent Activity by #{user.display_name}")
      expect(page).not_to have_selector('.columns')
    end

    it "tries to log in as another user" do
      visit "/users/masquerade/#{owner.id}"
      expect(page.current_path).to eq collections_list_path
      expect(page.find('.header_user')).not_to have_content owner.display_name
      expect(page).to have_content user.display_name
      expect(page).not_to have_selector('a', text: 'Undo Login As')
    end

    it "adds a note", js: true do
      visit collection_transcribe_page_path(collection.owner, collection, work_page.work, work_page)
      fill_in 'Write a new note or ask a question...', with: "Test note"
      find('#save_note_button').click
      expect(page).to have_content "Note has been created"
      find('#finish_button_top').click
      expect(page).to have_content('Saved')
    end

    it "Allows owner to delete note", skip_before: true do
      create(:note, user: user, body: 'Test note', collection: collection, work: work, page: work_page)
      login_as(owner, scope: :user)
      visit collection_transcribe_page_path(collection.owner, collection, work_page.work, work_page)
      expect(page).to have_content "Test note"
      expect(page).to have_selector('.user-bubble_actions > a[title="Delete"]')
    end

    it "tries to save transcription with unsaved note", js: true do
      col = work.collection
      test_page = work.pages.first
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      text = Page.find_by(id: test_page.id).source_text
      fill_in('Write a new note or ask a question...', with: "Test two")
      fill_in_editor_field "Attempt to save"
      message = dismiss_confirm do
        find('#save_button_top').click
      end
      expect(message).to have_content("You have unsaved notes.")
      new_text = Page.find_by(id: test_page.id).source_text
      # because of the note, page.source_text should not have changed
      expect(new_text).to eq text
    end

    it "deletes a note", js: true do
      col = collection
      test_page = work_page
      note = create(:note, user: user, body: 'Test note', collection: col, work: work, page: test_page)
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      page.find('.user-bubble_content', text: "Test note")
      accept_alert do
        find("form[data-turbo='true'][data-turbo-confirm='Are you sure you want to delete this note?'][action='/notes/#{note.id}'] button[type='submit']").click
      end
      expect(page).not_to have_selector('.user-bubble_content', text: 'Test note')
      expect(Note.find_by(id: note.id)).to be_nil
    end

    it "uses page arrows with unsaved transcription", js: true do
      col = collection
      test_page = work_pages.second
      # next page arrow
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      fill_in_editor_field "Attempt to save"
      message = accept_alert do
        page.click_link("Next page")
      end
      expect(message).to have_content("You have unsaved changes.")
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      # previous page arrow - make sure it also works with notes
      fill_in('Write a new note or ask a question...', with: "Test two")
      message = accept_alert do
        page.click_link("Previous page")
      end
      expect(message).to have_content("You have unsaved changes.")
    end

    it "filters list of pages the need transcription" do
      work_pages.first(2).each { |work_page| work_page.update_columns(status: :transcribed) }
      visit collection_read_work_path(work.collection.owner, work.collection, work)
      expect(page).to have_content(work.title)
      pages = work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end

      # look at pages that need transcription
      click_button('Pages That Need Transcription')

      # first two pages are transcribed; they shouldn't show up
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.second.title)
      # next three pages aren't transcribed; they shold show up
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fifth.title)
      expect(page).to have_button('View All Pages')
      expect(page.find('.pagination_info')).to have_content(work.pages.needs_transcription.count)

      # return to original list
      click_button('View All Pages')
      pages = work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end
      expect(page).to have_button('Pages That Need Transcription')
      expect(page.find('.pagination_info')).to have_content(work.pages.count)
    end

    it "filters list of pages the need translation" do
      work_pages.first.update_columns(translation_status: :translated)
      visit collection_read_work_path(work.collection.owner, work.collection, work)
      expect(page).to have_content(work.title)
      pages = work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end

      # look at pages that need transcription
      click_button('Pages That Need Translation')
      # first page is translated; it shouldn't show up
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
      # next three pages aren't translated; they shold show up
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.second.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
      expect(page).to have_button('View All Pages')
      expect(page.find('.pagination_info')).to have_content(work.pages.needs_translation.count)

      # return to original list
      click_button('View All Pages')
      pages = work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end
      expect(page).to have_button('Pages That Need Translation')
      expect(page.find('.pagination_info')).to have_content(work.pages.count)
    end

    it "finds a page to transcribe" do
      visit collection_path(collection.owner, collection)
      expect(page).to have_selector('h1', text: collection.title)
      expect(page).to have_content("About")
      expect(page).to have_content("Works")
      expect(page).to have_selector('a', text: "Start Transcribing")
      click_link("Start Transcribing")
      expect(page).to have_selector("#page_source_text")
    end


    it "adds an abusive note", js: true do
      flag_count = Flag.count
      visit collection_transcribe_page_path(collection.owner, collection, work_page.work, work_page)
      fill_in 'Write a new note or ask a question...', with: "Visit <a href=\"www.spam.com\">our store!</a>"
      find('#save_note_button').click
      expect(page).to have_content "Note has been created"
      expect(Flag.count).to eq(flag_count + 1)
    end

    it "adds an abusive transcript" do
      flag_count = Flag.count
      visit collection_transcribe_page_path(collection.owner, collection, work_page.work, work_page)
      fill_in_editor_field "Visit <a href=\"www.spam.com\">our store!</a>"
      find('#save_button_top').click
      expect(Flag.count).to eq(flag_count + 1)
    end

    it "adds an abusive translation" do
      abusive_content = 'Visit <a href="www.spam.com">our store!</a>'
      work_page.update_columns(source_text: abusive_content)
      flag_count = Flag.count
      visit collection_translate_page_path(collection.owner, collection, work_page.work, work_page)
      fill_in_editor_field abusive_content
      click_button('Save Changes')
      expect(Flag.count).to eq(flag_count + 1)
    end
  end
end
