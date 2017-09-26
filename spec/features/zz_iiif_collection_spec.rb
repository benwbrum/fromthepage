require 'spec_helper'

describe "uploads data for collections", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @at_id = "https://textgridlab.org/1.0/iiif/manifests/collection/published.json"
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "imports explores IIIF universe" do
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.find('a', text: 'Explore').click
    expect(page).to have_content("Collection: IIIF Universe")
    expect(page).to have_content("Collections")
    expect(page).not_to have_content("Manifests")
  end

  it "imports an IIIF collection", :js => true do
    #test import of collection
    visit dashboard_owner_path
    page.find('.tabs').click_link("Start A Project")
    page.fill_in 'at_id', with: @at_id
    click_button('Import')
    expect(page).to have_content(@at_id)
    expect(page).to have_content("Manifests")
    select("Create Collection", :from => 'manifest_import')
    click_button('Import Checked Manifests')
    expect(page.find('.flash_message')).to have_content("IIIF collection import is processing")
    expect(page).to have_content("Works")
    sleep(15)
    expect(Collection.last.title).to have_content("TextGrid")
    expect(Collection.last.works.count).to eq 1
  end

end
