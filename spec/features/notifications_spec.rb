require 'spec_helper'

describe "notifications", order: :defined do
  let(:owner_user) { create(:owner) }
  let(:regular_user) { create(:unique_user) }
  let(:admin_user) { create(:admin) }
  let(:collection) { create(:collection, :with_pages, owner_user_id: owner_user.id) }
  let(:work) { collection.works.first }
  let(:page_record) { work.pages.first }

  before :each do
    DatabaseCleaner.start
  end

  after :each do
    DatabaseCleaner.clean
  end

  it "resets note notifications" do
    login_as(owner_user, scope: :user)
    visit user_profile_path(owner_user)
    page.find('a.button', text: 'Edit Profile').click
    page.uncheck('user_notifications[note_added]')
    click_button('Update Profile')
    expect(page.current_path).to eq user_profile_path(owner_user)
    expect(owner_user.reload.notification.note_added).to be false
  end

  it "adds a response note (with email)", js: true do
    owner_user.notification.update!(note_added: false)
    login_as(regular_user, scope: :user)
    # now the actual test
    visit collection_transcribe_page_path(collection.owner, collection, page_record.work, page_record)
    ActionMailer::Base.deliveries.clear
    fill_in('Write a new note or ask a question...', with: "Note by user")
    find('#save_note_button').click
    expect(page).to have_content "Note has been created"
    # no email should be generated, because this is the same user as the previous note
    expect(ActionMailer::Base.deliveries).to be_empty
    logout(:user)
    # login as different user for next note.
    login_as(owner_user, scope: :user)
    visit collection_transcribe_page_path(collection.owner, collection, page_record.work, page_record)
    fill_in('Write a new note or ask a question...', with: "Email test note")
    find('#save_note_button').click
    expect(page).to have_content "Note has been created"
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.from).to include SENDING_EMAIL_ADDRESS
    expect(ActionMailer::Base.deliveries.first.to).to include regular_user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "New FromThePage Note"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match("Email test note")
    # log back in as user; make sure owner doesn't receive an email
    logout(:user)
    ActionMailer::Base.deliveries.clear
    login_as(admin_user, scope: :user)
    visit collection_transcribe_page_path(collection.owner, collection, page_record.work, page_record)
    fill_in('Write a new note or ask a question...', with: "Final note")
    find('#save_note_button').click
    expect(page).to have_content "Note has been created"
    # user should receive an email, but owner should not
    expect(ActionMailer::Base.deliveries).not_to be_empty
    emails = ActionMailer::Base.deliveries.map { |mail| mail.to }
    expect(emails).to include [regular_user.email]
    expect(emails).not_to include [owner_user.email]
    expect(ActionMailer::Base.deliveries.first.subject).to eq "New FromThePage Note"
  end
end
