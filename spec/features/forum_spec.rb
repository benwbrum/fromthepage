# frozen_string_literal: true

require 'spec_helper'

describe 'forum tab for collection' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      title: "Forum Collection #{SecureRandom.hex(4)}"
    )
  end

  before do
    login_as(owner, scope: :user)
  end

  after do
    messageboard_group = collection.reload.messageboard_group
    collection.destroy!
    Thredded::Messageboard.where(messageboard_group_id: messageboard_group.id).destroy_all if messageboard_group
    messageboard_group&.destroy!
    owner.destroy!
  end

  it 'enables, accesses, and disables the collection forum', js: true do
    visit collection_path(owner, collection)
    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Look & Feel')

    page.check('Enable forums')

    expect(page).to have_checked_field('Enable forums')
    expect(page).to have_content('Collection has been updated')
    expect(collection.reload).to be_messageboards_enabled

    page.find('.tabs').click_link('Forum')

    expect(page).to have_content('All Messageboards')
    expect(page).to have_content('Create a New Messageboard')

    page.find('.tabs').click_link('Settings')
    page.find('.side-tabs').click_link('Look & Feel')
    page.uncheck('Enable forums')

    expect(page).to have_unchecked_field('Enable forums')
    expect(collection.reload).not_to be_messageboards_enabled

    visit current_path

    expect(page.find('.tabs')).not_to have_link('Forum')
  end
end
