# frozen_string_literal: true

require 'spec_helper'

describe 'notifications' do
  before do |example|
    DatabaseCleaner.start unless example.metadata[:js]
    ActionMailer::Base.deliveries.clear
  end

  after do |example|
    ActionMailer::Base.deliveries.clear

    if example.metadata[:js]
      collection.destroy!
      [admin, user, owner].each(&:destroy!)
    else
      DatabaseCleaner.clean
    end
  end

  let(:owner) { create(:unique_user, :owner, activity_email: true) }
  let(:user) { create(:unique_user, activity_email: true) }
  let(:admin) { create(:unique_user, :admin, activity_email: true) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner) }
  let(:work_page) { create(:page, work: work) }

  it 'resets note notifications' do
    login_as(owner, scope: :user)
    visit user_profile_path(owner)
    page.find('a.button', text: 'Edit Profile').click
    page.uncheck('user_notifications[note_added]')
    click_button('Update Profile')

    expect(page.current_path).to eq user_profile_path(owner)
    expect(owner.reload.notification.note_added).to be false
  end

  it 'adds a response note (with email)', js: true do
    owner.notification.update!(note_added: false)

    login_as(user, scope: :user)
    visit collection_transcribe_page_path(collection.owner, collection, work, work_page)
    fill_in('Write a new note or ask a question...', with: 'Note by user')
    find('#save_note_button').click

    expect(page).to have_content 'Note has been created'
    expect(ActionMailer::Base.deliveries).to be_empty

    logout(:user)
    login_as(owner, scope: :user)
    visit collection_transcribe_page_path(collection.owner, collection, work, work_page)
    fill_in('Write a new note or ask a question...', with: 'Email test note')
    find('#save_note_button').click

    expect(page).to have_content 'Note has been created'
    expect(ActionMailer::Base.deliveries).not_to be_empty

    response_email = ActionMailer::Base.deliveries.find { |mail| mail.to.include?(user.email) }
    expect(response_email).to be_present
    expect(response_email.from).to include SENDING_EMAIL_ADDRESS
    expect(response_email.subject).to eq 'New FromThePage Note'
    expect(response_email.body.encoded).to match('Email test note')

    logout(:user)
    ActionMailer::Base.deliveries.clear
    login_as(admin, scope: :user)
    visit collection_transcribe_page_path(collection.owner, collection, work, work_page)
    fill_in('Write a new note or ask a question...', with: 'Final note')
    find('#save_note_button').click

    expect(page).to have_content 'Note has been created'
    expect(ActionMailer::Base.deliveries).not_to be_empty

    recipients = ActionMailer::Base.deliveries.map(&:to)
    expect(recipients).to include [user.email]
    expect(recipients).not_to include [owner.email]
    expect(ActionMailer::Base.deliveries.first.subject).to eq 'New FromThePage Note'
  end
end
