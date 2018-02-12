require 'spec_helper'

describe "notifications" , :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @user = User.find_by(login: USER)
    @admin = User.find_by(login: ADMIN)
    @collection = Collection.first
    @work = @collection.works.first
    @page = @work.pages.first
  end

  it "resets note notifications" do
    login_as(@owner, :scope => :user)
    visit user_profile_path(@owner)
    page.find('a.button', text: 'Edit Profile').click
    page.uncheck('user_notifications[note_added]')
    click_button('Update Profile')
    expect(page.current_path).to eq user_profile_path(@owner)
    #reset owner object for updated information
    @owner = User.find_by(login: OWNER)
    expect(@owner.notification.note_added).to be false
  end

  it "adds a response note (with email)" do
    login_as(@user, :scope => :user)
    #now the actual test
    visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
    ActionMailer::Base.deliveries.clear
    fill_in('Write a new note...', with: "Note by user")
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    #no email should be generated, because this is the same user as the previous note
    expect(ActionMailer::Base.deliveries).to be_empty
    logout(:user)
    #login as different user for next note.
    login_as(@owner, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
    fill_in('Write a new note...', with: "Email test note")
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    expect(ActionMailer::Base.deliveries).not_to be_empty
    expect(ActionMailer::Base.deliveries.first.from).to include SENDING_EMAIL_ADDRESS
    expect(ActionMailer::Base.deliveries.first.to).to include @user.email
    expect(ActionMailer::Base.deliveries.first.subject).to eq "New FromThePage Note"
    expect(ActionMailer::Base.deliveries.first.body.encoded).to match("Email test note")
    #log back in as user; make sure owner doesn't receive an email
    logout(:user)
    ActionMailer::Base.deliveries.clear
    login_as(@admin, :scope => :user)
    visit collection_transcribe_page_path(@collection.owner, @collection, @page.work, @page)
    fill_in('Write a new note...', with: "Final note")
    click_button('Submit')
    expect(page).to have_content "Note has been created"
    #user should receive an email, but owner should not
    expect(ActionMailer::Base.deliveries).not_to be_empty
    emails = ActionMailer::Base.deliveries.map {|mail| mail.to}
    expect(emails).to include [@user.email]
    expect(emails).not_to include [@owner.email]
    expect(ActionMailer::Base.deliveries.first.subject).to eq "New FromThePage Note"
  end

end