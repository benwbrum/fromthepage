require 'spec_helper'

FIELD_XML = <<EOF
<?xml version='1.0' encoding='UTF-8'?>
      <page>
        <p><span class='field__label'>Last Name: </span>Mitchell</p><p><span class='field__label'>First Name: </span>John</p><p><span class='field__label'>Middle Name: </span></p><p><span class='field__label'>Suffix or Title: </span></p><p><span class='field__label'>Home Town: </span>Pinson</p><p><span class='field__label'>Home County: </span>Jefferson</p><p><span class='field__label'>Home State: </span>Alabama</p><p><span class='field__label'>Race: </span>Caucasian</p><p><span class='field__label'>Gender: </span></p><p><span class='field__label'>Branch: </span>Army</p><p><span class='field__label'>Service Number: </span>14208593</p><p><span class='field__label'>See Also: </span></p><p><span class='field__label'>Notes: </span></p><p/>
      </page>
EOF


describe "editor actions" , :order => :defined do
  context "Factory" do
    before :all do
      @user = User.find_by(login: USER)
    end
    before :each do
      login_as(@user, :scope => :user)
      DatabaseCleaner.start
    end
    after :each do
      DatabaseCleaner.clean
    end

    let(:collection){ create(:collection ) }
    let(:work)      { create(:work, collection: collection) }
    let(:page_fact) { create(:page, work: work) }

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

  context "Legacy Group" do
    before :all do
      @owner = User.find_by(login: OWNER)
      @user = User.find_by(login: USER)
      @rest_user = User.find_by(login: REST_USER)
      collection_ids = Deed.where(user_id: @user.id).distinct.pluck(:collection_id)
      @collections = Collection.where(id: collection_ids)
      @collection = @collections.first
      @work = @collection.works.first
      @page = @work.pages.first
      @auth_work = Collection.find(3).works.second
      #set up the restricted user not to be emailed
      notification = Notification.find_by(user_id: @rest_user.id)
      notification.add_as_collaborator = false
      notification.save!
    end

    before :each do
      login_as(@user, :scope => :user)
    end

    it "checks that a restricted editor can't see a work" do
      logout(:user)
      login_as(@rest_user, :scope => :user)
      visit collection_read_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
      page.find('.work-page_title', text: @work.pages.first.title).click_link
      expect(page.find('.tabs')).not_to have_content("Transcribe")
    end

    it 'adds a user to a restricted work' do
      ActionMailer::Base.deliveries.clear
      logout(:user)
      login_as(@owner, scope: :user)
      visit edit_collection_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
      page.click_link 'Edit Collaborators'
      # this user should not get an email
      select(@rest_user.name_with_identifier, from: 'scribe_id')
      page.find('.add_scribe').click
      expect(ActionMailer::Base.deliveries).to be_empty
      # this user should get an email
      select(@user.name_with_identifier, from: 'scribe_id')
      page.find('.add_scribe').click
      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.first.to).to include @user.email
      expect(ActionMailer::Base.deliveries.first.subject).to eq "You've been added to #{@auth_work.title}"
      expect(ActionMailer::Base.deliveries.first.body.encoded).to match('added you as a collaborator')
    end

    it 'checks that an editor with permissions can see a restricted work' do
      visit collection_read_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
      page.find('.work-page_title', text: @work.pages.first.title).click_link
      expect(page.find('.tabs')).to have_content('Transcribe')
    end

    it 'removes a collaborator from a restricted work' do
      logout(:user)
      login_as(@owner, scope: :user)
      visit edit_collection_work_path(@auth_work.owner, @auth_work.collection, @auth_work)
      page.click_link 'Edit Collaborators'
      page.find('.user-label', text: @rest_user.name_with_identifier).find('button.remove').click
      expect(page).not_to have_selector('.user-label', text: @rest_user.name_with_identifier)
    end

    it "looks at a collection" do
      visit dashboard_watchlist_path
      page.find('h4', text: @collection.title).click_link(@collection.title)
      expect(page).to have_content("Works")
      expect(page).to have_content(@work.title)
      expect(page).not_to have_content("Collection Footer")
      #check the tabs in the collection
      #Subjects
      page.find('.tabs').click_link("Subjects")
      expect(page).to have_content("People")
      expect(page).to have_content("Places")
      #Statistics
      page.find('.tabs').click_link("Statistics")
      expect(page).to have_content("Collaborators")
      #make sure we don't have the owner tabs
      expect(page.find('.tabs')).not_to have_content("Settings")
      expect(page.find('.tabs')).not_to have_content("Export")
      expect(page.find('.tabs')).not_to have_content("Collaborators")
    end

    it "looks at a work" do
      visit collection_path(@collection.owner, @collection)
      page.find('.collection-work_title', text: @work.title).click_link
      expect(page).to have_content(@page.title)
      #Check the tabs in the work
      #About
      page.find('.tabs').click_link("About")
      expect(page).to have_content(@work.title)
      expect(page).to have_content("Description")
      #Help
      page.find('.tabs').click_link("Help")
      expect(page).to have_content("Transcribing")
      expect(page).to have_content("Linking Subjects")
      #Contents
      page.find('.tabs').click_link("Contents")
      expect(page).to have_content("Page Title")
      expect(page).to have_content(@work.pages.last.title)
      within(page.find('tr', text: @work.pages.last.title)) do
        page.find('a', text: 'Transcribe').click
      end
      expect(page).to have_content("Transcription Conventions")
      expect(page).to have_selector("textarea")
    end

    it "looks at pages" do
      visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
      expect(page).to have_content("please help transcribe this page")
      page.find('.work-page_title', text: @page.title).click_link
      page.find('#page_source_text')
      expect(page).to have_button('Preview')
      expect(page).to have_content(@page.title)
      expect(page).not_to have_content("Collection Footer")
      #Versions
      page.find('.tabs').click_link("Versions")
      expect(page).to have_content("revisions")
    end

    it "transcribes a page" do
      visit "/display/display_page?page_id=#{@page.id}"
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
      @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
      visit "/display/display_page?page_id=#{@work.pages.first.id}"
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

    it "translation displays transcription text by default", :js => true do
      @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
      visit "/display/display_page?page_id=#{@work.pages.first.id}"
      page.find('.tabs').click_link("Translate")
      expect(page).to_not have_selector('.page-imagescan')
      expect(page).to have_selector('.page-preview')
    end
    # it "translation toggles image display", :js => true do
    #   @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
    #   visit "/display/display_page?page_id=#{@work.pages.first.id}"
    #   page.find('.tabs').click_link("Translate")
    #   print "\n\n\nInitial tab load before clicking show image:\n"
    #   print page.text
    #   print "\n\n\n"
    #   print "Style of imagescan div, preview div, and toggle button before clicking show image:\n"
    #   begin
    #     print page.find('#toggleImage')[:style]
    #     print page.find('.page-imagescan')[:style]
    #     print page.find('.page-preview')[:style]
    #   rescue Capybara::ElementNotFound => e
    #     print e.message + "\n"
    #   end
    #   print "\n\n\n"

    #   page.click_button("Show Image")
    #   sleep(2)
    #   print "\n\n\nPage contents after clicking show image:\n"
    #   print page.text
    #   print "\n\n\n"
    #   print "Style of imagescan div, preview div, and toggle button before clicking show image:\n"
    #   begin
    #     print page.find('#toggleImage')[:style]
    #     print page.find('.page-imagescan')[:style]
    #     print page.find('.page-preview')[:style]
    #   rescue Capybara::ElementNotFound => e
    #     print e.message + "\n"
    #   end
    #   print "\n\n\n"
    #   expect(page).to have_content('Show Transcription')
    #   expect(page).to have_selector('.page-imagescan')
    #   expect(page).to_not have_selector('.page-preview')
    # end

    it "checks a plain user profile" do
      login_as(@user, :scope => :user)
      visit dashboard_path
      page.find('a', text: 'Your Profile').click
      expect(page).to have_content(@user.display_name)
      expect(page).to have_content("Recent Activity by #{@user.display_name}")
      expect(page).not_to have_selector('.columns')
    end

    it "tries to log in as another user" do
      visit "/users/masquerade/#{@owner.id}"
      expect(page.current_path).to eq collections_list_path
      expect(page.find('.header_user')).not_to have_content @owner.display_name
      expect(page).to have_content @user.display_name
      expect(page).not_to have_selector('a', text: 'Undo Login As')
    end

    it "adds a note" do
      visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
      fill_in 'Write a new note or ask a question...', with: "Test note"
      find('#save_note_button').click
      expect(page).to have_content "Note has been created"
      find('#finish_button_top').click
      expect(page).to have_content('Saved')
    end

    it "Allows owner to delete note", skip_before: true do
      login_as(@owner, :scope => :user)
      visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
      expect(page).to have_content "Test note"
      expect(page).to have_selector('.user-bubble_actions > a[title="Delete"]')
    end

    it "tries to save transcription with unsaved note", :js => true do
      col = Collection.second
      test_page = col.works.first.pages.first
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      text = Page.find_by(id: test_page.id).source_text
      fill_in('Write a new note or ask a question...', with: "Test two")
      fill_in_editor_field "Attempt to save"
      message = dismiss_confirm do
        find('#finish_button_top').click
      end
      sleep(2)
      expect(message).to have_content("You have unsaved notes.")
      new_text = Page.find_by(id: test_page.id).source_text
      #because of the note, page.source_text should not have changed
      expect(new_text).to eq text
      #save the note
      begin
        find('#blankPageButton').click
      rescue Capybara::ElementNotFound => e
        print e.message + "\n"
      end
      find('#save_note_button').click
      expect(test_page.notes.count).not_to be nil
    end

    it "deletes a note", :js => true do
      col = Collection.second
      test_page = col.works.first.pages.first
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      title = test_page.notes.last.id
      page.find('.user-bubble_content', text: "Test two")
      accept_alert do
        page.click_link('', :href => "/notes/#{title}")
      end
      sleep(3)
      expect(Note.find_by(id: title)).to be_nil
    end

    it "uses page arrows with unsaved transcription", :js => true do
      col = Collection.second
      test_page = col.works.first.pages.second
      #next page arrow
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      fill_in_editor_field "Attempt to save"
      message = accept_alert do
        page.click_link("Next page")
      end
      sleep(10)
      expect(message).to have_content("You have unsaved changes.")
      visit collection_transcribe_page_path(col.owner, col, test_page.work, test_page)
      #previous page arrow - make sure it also works with notes
      fill_in('Write a new note or ask a question...', with: "Test two")
      message = accept_alert do
        page.click_link("Previous page")
      end
      sleep(10)
      expect(message).to have_content("You have unsaved changes.")
    end

    it "filters list of pages the need transcription" do
      visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
      expect(page).to have_content(@work.title)
      pages = @work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end

      #look at pages that need transcription
      click_button('Pages That Need Transcription')

      #first two pages are transcribed; they shouldn't show up
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.second.title)
      #next three pages aren't transcribed; they shold show up
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fifth.title)
      expect(page).to have_button('View All Pages')
      expect(page.find('.pagination_info')).to have_content(@work.pages.needs_transcription.count)

      #return to original list
      click_button('View All Pages')
      pages = @work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end
      expect(page).to have_button('Pages That Need Transcription')
      expect(page.find('.pagination_info')).to have_content(@work.pages.count)
    end

    it "filters list of pages the need translation" do
      @work = Work.where("supports_translation = ? && restrict_scribes = ?", true, false).first
      visit collection_read_work_path(@work.collection.owner, @work.collection, @work)
      expect(page).to have_content(@work.title)
      pages = @work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end

      #look at pages that need transcription
      click_button('Pages That Need Translation')
      #first page is translated; it shouldn't show up
      expect(page.find('.maincol')).not_to have_selector('.work-page_title', text: pages.first.title)
      #next three pages aren't translated; they shold show up
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.second.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.third.title)
      expect(page.find('.maincol')).to have_selector('.work-page_title', text: pages.fourth.title)
      expect(page).to have_button('View All Pages')
      expect(page.find('.pagination_info')).to have_content(@work.pages.needs_translation.count)

      #return to original list
      click_button('View All Pages')
      pages = @work.pages.limit(5)
      pages.each do |p|
        expect(page.find('.maincol')).to have_selector('.work-page_title', text: p.title)
      end
      expect(page).to have_button('Pages That Need Translation')
      expect(page.find('.pagination_info')).to have_content(@work.pages.count)
    end

    it "finds a page to transcribe" do
      visit collection_path(@collection.owner, @collection)
      expect(page).to have_selector('h1', text: @collection.title)
      expect(page).to have_content("About")
      expect(page).to have_content("Works")
      expect(page).to have_selector('a', text: "Start Transcribing")
      click_link("Start Transcribing")
      expect(page).to have_selector("#page_source_text")
    end


    it "adds an abusive note" do
      flag_count = Flag.count
      visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
      fill_in 'Write a new note or ask a question...', with: "Visit <a href=\"www.spam.com\">our store!</a>"
      find('#save_note_button').click
      expect(page).to have_content "Note has been created"
      expect(Flag.count).to eq(flag_count + 1)
    end

    it "adds an abusive transcript" do
      flag_count = Flag.count
      visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
      fill_in_editor_field "Visit <a href=\"www.spam.com\">our store!</a>"
      find('#save_button_top').click
      expect(Flag.count).to eq(flag_count + 1)
    end

    it "adds an abusive translation" do
      flag_count = Flag.count
      visit collection_translate_page_path(@collection.owner, @collection, @page.work, @page)
      fill_in_editor_field "Visit <a href=\"www.spam.com\">our store!</a>"
      find('#save_button_top').click
      expect(Flag.count).to eq(flag_count + 1)
    end

  end
end
