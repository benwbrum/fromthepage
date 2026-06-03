require 'spec_helper'

describe "owner view - collection" do
  let(:owner_user) { create(:owner) }
  let(:collections) do
    [
      create(:collection, :with_pages, owner_user_id: owner_user.id),
      create(:collection, :with_pages, owner_user_id: owner_user.id)
    ]
  end
  let(:collection) { collections.first }
  let(:works) { owner_user.owner_works }
  let(:collaborator_user) { create(:unique_user) }

  let(:people_category) { create(:category, collection: collection, title: 'People') }
  let(:places_category) { create(:category, collection: collection, title: 'Places') }
  let(:collaborator_deed) do
    create(:deed,
           user: collaborator_user,
           collection: collection,
           work: collection.works.first,
           page: collection.works.first.pages.first,
           deed_type: DeedType::PAGE_TRANSCRIPTION)
  end

  before :each do
    DatabaseCleaner.start
    collections
    people_category
    places_category
    collaborator_deed
    login_as(owner_user, scope: :user)
  end

  after :each do
    DatabaseCleaner.clean
  end

  it "looks at owner tabs" do
    visit dashboard_owner_path
    expect(page).to have_selector('.owner-info')
    expect(page).to have_content("#{owner_user.account_type} account since #{owner_user.start_date.strftime('%b %d, %Y')}")
    # look at owner stats in dashboard
    expect(page.find('.owner-counters .counter[1]')['data-prefix'].to_i).to eq owner_user.all_owner_collections.count
    expect(page.find('.owner-counters .counter[2]')['data-prefix'].to_i).to eq works.count
    # look at tabs
    page.find('.tabs').click_link("Start A Project")
    expect(page.current_path).to eq '/dashboard/startproject'
    expect(page).to have_content("Upload PDF or ZIP File")
    page.find('.tabs').click_link("Your Collections")
    expect(page.current_path).to eq dashboard_owner_path
  end

  it "looks at statistics tab" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Summary")
    expect(page).to have_selector('.collection-stats_counters')
    expect(page).to have_content("Statistics from")
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq works.count
    expect(page.find('.collection-users')).to have_content('Transcribing')
    expect(page.find('.collection-users')).to have_content('Editing')
    expect(page.find('.collection-users')).to have_content('Indexing')
    expect(page.find('.collection-users')).to have_content(owner_user.all_collaborators.last.display_name)
  end

  it "looks at subjects tab" do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    expect(page).to have_content("People")
    expect(page).to have_content("Places")
  end

  it "looks at statistics tab" do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Works")
    expect(page).to have_content("Collaborators")
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq collection.works.count
  end

  it "looks at works list tab" do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link("Works List")
    expect(page).to have_content("Works")
    collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at settings tab" do
    visit "/collection/show?collection_id=#{collection.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content(collection.title)
    expect(page).to have_content("Danger Zone")
  end

  it "looks at export tab" do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content(collection.title)
    collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at collaborators tab" do
    visit collection_path(collection.owner, collection)
    page.find('.tabs').click_link("Collaborators")
    expect(page).to have_content(collection.title)
    expect(page).to have_content("Contributions Between")
    expect(page).to have_content("Active Collaborators")
    expect(page).to have_content("All Collaborator Emails")
    all_transcribers = User.includes(:deeds).where(deeds: { collection_id: collection.id }).distinct
    all_transcribers.each do |t|
      expect(page.find('#collaborators')).to have_content(t.email)
    end
  end
end
