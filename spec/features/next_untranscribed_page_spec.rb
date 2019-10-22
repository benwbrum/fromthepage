# frozen_string_literal: true

require 'spec_helper'

describe "Next untranscribed page logic" do
  before :all do
  end
  before :each do
    DatabaseCleaner.start
    login_as(user, scope: :user)
  end
  after :each do
    DatabaseCleaner.clean
  end

  let(:user)  { create(:user) }
  let(:owner) { create(:owner) }

  let(:new_work) { create(:work, :with_pages) }
  let(:completed_work) { create(:work, :transcribed) }
  let(:restricted_work) { create(:work, :restricted, :with_pages) }

  it "doesn't show the next button on reading page" do
    collection = create(:collection, works: [new_work])
    visit collection_display_page_path(collection.owner, collection, new_work, new_work.pages.last)

    expect(page).to(have_content(new_work.pages.last.title))
    expect(page).to(have_css('a.page-nav_prev'))
    expect(page).to(have_css('span.page-nav_next'))
  end
  it "shows the next button on the transcribe page" do
    collection = create(:collection, works: [new_work])
    visit collection_transcribe_page_path(collection.owner, collection, new_work, new_work.pages.last)

    expect(page).to(have_content(new_work.pages.last.title))
    expect(page).to(have_css('a.page-nav_prev'))
    expect(page).to(have_css('a.page-nav_next'))
  end

  context "Clicking `next` on the last page of a work" do
    it "takes user to page in work when the work is incomplete" do
      collection = create(:collection, works: [new_work])
      visit collection_transcribe_page_path(collection.owner, collection, new_work, new_work.pages.last)

      expect(page).to(have_content(new_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this work"))
      expect(page).to(have_content(new_work.pages.first.title))
    end
    it "takes user to page in docset when work is complete" do
      collection = create(:collection, works: [new_work, completed_work])
      docset = create(:document_set, :public, collection_id: collection.id, works: [new_work, completed_work])

      visit collection_transcribe_page_path(docset.owner, docset.slug, completed_work, completed_work.pages.last)
      expect(page).to(have_content(docset.title))

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this collection"))
      expect(page).to(have_content(new_work.pages.first.title))
    end

    it "takes user to page in collection when docset is complete" do
      collection = create(:collection, works: [new_work, completed_work])
      docset = create(:document_set, :public, collection_id: collection.id, works: [completed_work])

      visit collection_transcribe_page_path(docset.owner, docset.slug, completed_work, completed_work.pages.last)
      expect(page).to(have_content(docset.title))

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this collection"))
      expect(page).to(have_content(new_work.pages.first.title))
    end
    it "takes user to page in collection when work is complete" do
      collection = create(:collection, works: [new_work, completed_work])
      visit collection_transcribe_page_path(collection.owner, collection, completed_work, completed_work.pages.last)

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this collection"))
      expect(page).to(have_content(new_work.pages.first.title))
    end
    it "takes user to owner profile page when collection is complete" do
      collection = create(:collection, works: [completed_work])
      visit collection_transcribe_page_path(collection.owner, collection, completed_work, completed_work.pages.last)

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("There are no more pages to transcribe in this collection"))
      expect(page.current_path).to(eq(user_profile_path(collection.owner)))
    end
    it "handles when user lacks permissions to view page in a work in a docset" do
      collection = create(:collection, works: [restricted_work, completed_work, new_work])
      docset = create(:document_set, :public, collection_id: collection.id, works: [restricted_work, completed_work, new_work])

      visit collection_transcribe_page_path(docset.owner, docset.slug, completed_work, completed_work.pages.last)
      expect(page).to(have_content(docset.title))

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this collection"))
      expect(page).to(have_content(new_work.pages.first.title))
    end
    it "handles when user lacks permissions to view page in collection" do
      collection = create(:collection, works: [restricted_work, completed_work, new_work])
      docset = create(:document_set, :public, collection_id: collection.id, works: [restricted_work, completed_work])

      visit collection_transcribe_page_path(docset.owner, docset.slug, completed_work, completed_work.pages.last)
      expect(page).to(have_content(docset.title))

      expect(page).to(have_content(completed_work.pages.last.title))
      page.find("a.page-nav_next").click

      expect(page).to(have_content("Here's another page in this collection"))
      expect(page).to(have_content(new_work.pages.first.title))
    end
  end
end
