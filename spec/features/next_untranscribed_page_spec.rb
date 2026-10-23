# frozen_string_literal: true

require 'spec_helper'

describe 'Next untranscribed page logic' do
  before do
    DatabaseCleaner.start
    login_as(user, scope: :user)
  end

  after do
    DatabaseCleaner.clean
  end

  let(:user) { create(:unique_user) }
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:new_work) { create(:work, :with_pages, collection: collection, owner: owner) }
  let(:completed_work) { create(:work, :transcribed, collection: collection, owner: owner) }
  let(:restricted_work) { create(:work, :restricted, :with_pages, collection: collection, owner: owner) }

  it 'does not show the next button on reading page' do
    visit collection_display_page_path(owner, collection, new_work, new_work.pages.last)

    expect(page).to have_content(new_work.pages.last.title)
    expect(page).to have_css('a.page-nav_prev')
    expect(page).to have_css('span.page-nav_next')
  end

  it 'shows the next button on the transcribe page' do
    visit collection_transcribe_page_path(owner, collection, new_work, new_work.pages.last)

    expect(page).to have_content(new_work.pages.last.title)
    expect(page).to have_css('a.page-nav_prev')
    expect(page).to have_css('a.page-nav_next')
  end

  context 'when clicking next on the last page of a work' do
    it 'takes user to page in work when the work is incomplete' do
      visit collection_transcribe_page_path(owner, collection, new_work, new_work.pages.last)

      expect(page).to have_content(new_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this work")
      expect(page).to have_content(new_work.pages.first.title)
    end

    it 'takes user to page in docset when work is complete' do
      document_set = create_document_set_with(new_work, completed_work)

      visit collection_transcribe_page_path(
        document_set.owner,
        document_set.slug,
        completed_work,
        completed_work.pages.last
      )
      expect(page).to have_content(document_set.title)
      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this collection")
      expect(page).to have_content(new_work.pages.first.title)
    end

    it 'takes user to page in collection when docset is complete' do
      new_work
      document_set = create_document_set_with(completed_work)

      visit collection_transcribe_page_path(
        document_set.owner,
        document_set.slug,
        completed_work,
        completed_work.pages.last
      )
      expect(page).to have_content(document_set.title)
      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this collection")
      expect(page).to have_content(new_work.pages.first.title)
    end

    it 'takes user to page in collection when work is complete' do
      new_work
      visit collection_transcribe_page_path(owner, collection, completed_work, completed_work.pages.last)

      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this collection")
      expect(page).to have_content(new_work.pages.first.title)
    end

    it 'takes user to owner profile page when collection is complete' do
      visit collection_transcribe_page_path(owner, collection, completed_work, completed_work.pages.last)

      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content('There are no more pages to transcribe in this collection')
      expect(page.current_path).to eq(user_profile_path(owner))
    end

    it 'handles when user lacks permissions to view page in a work in a docset' do
      document_set = create_document_set_with(restricted_work, completed_work, new_work)

      visit collection_transcribe_page_path(
        document_set.owner,
        document_set.slug,
        completed_work,
        completed_work.pages.last
      )
      expect(page).to have_content(document_set.title)
      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this collection")
      expect(page).to have_content(new_work.pages.first.title)
    end

    it 'handles when user lacks permissions to view page in collection' do
      document_set = create_document_set_with(restricted_work, completed_work)
      new_work

      visit collection_transcribe_page_path(
        document_set.owner,
        document_set.slug,
        completed_work,
        completed_work.pages.last
      )
      expect(page).to have_content(document_set.title)
      expect(page).to have_content(completed_work.pages.last.title)
      page.find('a.page-nav_next').click

      expect(page).to have_content("Here's another page in this collection")
      expect(page).to have_content(new_work.pages.first.title)
    end
  end

  def create_document_set_with(*works)
    create(
      :document_set,
      :public,
      collection_id: collection.id,
      owner_user_id: owner.id,
      works: works
    )
  end
end
