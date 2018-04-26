require 'spec_helper'

describe "owner view - collection" do

  before :all do

    @owner = User.find_by(login: OWNER)
    @collections = @owner.all_owner_collections
    @collection = @collections.first
    @works = @owner.owner_works
  end

  before :each do
    login_as(@owner, :scope => :user)
  end    

  it "looks at owner tabs" do
    visit dashboard_owner_path
    expect(page).to have_selector('.owner-info')
    expect(page).to have_content("#{@owner.account_type} account since #{@owner.start_date.strftime('%b %d, %Y')}")
    #look at owner stats in dashboard
    expect(page.find('.owner-counters .counter[1]')['data-prefix'].to_i).to eq @owner.all_owner_collections.count
    expect(page.find('.owner-counters .counter[2]')['data-prefix'].to_i).to eq @works.count
    expect(page.find('.owner-counters .counter[3]')['data-prefix'].to_i).to eq @owner.document_sets.count

    #look at tabs
    page.find('.tabs').click_link("Start A Project")
    expect(page.current_path).to eq '/dashboard/startproject'
    expect(page).to have_content("Upload PDF or ZIP File")
    page.find('.tabs').click_link("Your Works")
    expect(page.current_path).to eq dashboard_owner_path
  end

  it "looks at statistics tab" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Summary")
    expect(page).to have_selector('.collection-stats_counters')
    expect(page).to have_content("Last 7 Days Statistics")
    expect(page).to have_content("All Collaborator Emails")
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq @works.count
    expect(page.find('#collaborators')).to have_content(@owner.all_collaborators.first.display_name)
    expect(page.find('#collaborators')).to have_content(@owner.all_collaborators.first.email)
  end

  it "looks at subjects tab" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Subjects")
    expect(page).to have_content("Categories")
    expect(page).to have_content("People")
    expect(page).to have_content("Places")
  end

  it "looks at statistics tab" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Statistics")
    expect(page).to have_content("Works")
    expect(page).to have_content("Collaborators")
    expect(page.find('.collection-stats_counters[1] .counter[1]')['data-prefix'].to_i).to eq @collection.works.count
  end

  it "looks at works list tab" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Works List")
    expect(page).to have_content("Works")
    @collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at settings tab" do
    visit "/collection/show?collection_id=#{@collection.id}"
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content(@collection.title)
  end

  it "looks at export tab" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Export")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Export Subject Index")
    expect(page).to have_content("Export Individual Works")
    @collections.first.works.each do |w|
      expect(page).to have_content(w.title)
    end
  end

  it "looks at collaborators tab" do
    visit collection_path(@collection.owner, @collection)
    page.find('.tabs').click_link("Collaborators")
    expect(page).to have_content(@collection.title)
    expect(page).to have_content("Contributions Between")
    expect(page).to have_content("Active Collaborators")
    expect(page).to have_content("All Collaborator Emails")
    all_transcribers = User.includes(:deeds).where(deeds: {collection_id: @collection.id}).distinct
    all_transcribers.each do |t|
      expect(page.find('#collaborators')).to have_content(t.email)
    end
  end

end