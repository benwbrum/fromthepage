# frozen_string_literal: true

require 'spec_helper'

describe 'collection statistics' do
  let(:owner) { create(:unique_user, :owner) }
  let(:user) { create(:unique_user) }
  let(:collection_title) { "Statistics Collection #{SecureRandom.hex(4)}" }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      title: collection_title
    )
  end

  before do
    DatabaseCleaner.start
    ActionMailer::Base.deliveries.clear
  end

  after do
    ActionMailer::Base.deliveries.clear
    DatabaseCleaner.clean
  end

  it 'creates a collection as an owner' do
    login_as(owner, scope: :user)
    visit dashboard_owner_path
    page.find('a', text: 'Create a Collection').click
    fill_in 'collection_title', with: collection_title
    click_button('Create Collection')

    expect(page).to have_content(collection_title)
    expect(owner.all_owner_collections.find_by(title: collection_title)).to be_present
  end

  it 'shows the mailing-list export to a collection owner' do
    collection
    login_as(owner, scope: :user)
    visit dashboard_summary_path

    expect(page).to have_content('Collaborators')
    expect(page).to have_css('#mailing-list-export-submit')
  end

  it 'does not show the owner mailing-list export to a regular user' do
    collection
    login_as(user, scope: :user)
    visit dashboard_summary_path

    expect(page).not_to have_css('#mailing-list-export-submit')
  end

  it 'adds a user to the collection owners group' do
    collection
    user.notification.update!(add_as_owner: false)
    login_as(owner, scope: :user)
    visit collection_path(owner, collection)
    click_link 'Settings'
    page.find('.side-tabs').click_link('Privacy & Access')
    page.click_link 'Edit Owners'
    select(user.name_with_identifier, from: 'user_id')

    within '.user-select-form' do
      click_button 'Add'
    end

    expect(user.reload).to be_owner
    expect(collection.reload.owners).to include(user)
  end

  it 'shows the mailing-list export to an added collection owner' do
    user.update!(owner: true)
    collection.owners << user
    login_as(user, scope: :user)
    visit dashboard_summary_path

    expect(page).to have_css('#mailing-list-export-submit')
  end
end
