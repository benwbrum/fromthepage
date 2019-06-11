require 'spec_helper'

describe "uploads data for collections", :order => :defined do
  Capybara.javascript_driver = :webkit

  before :all do
    @owner = User.find_by(login: OWNER)
    @at_id = "https://cudl.lib.cam.ac.uk/iiif/collection/hebrew"
  end

  before :each do
    login_as(@owner, :scope => :user)
  end

  it "imports explores IIIF universe" do
    VCR.use_cassette('iiif/iiif-universe') do
      visit dashboard_owner_path
      page.find('.tabs').click_link("Start A Project")
      page.find('a', text: 'Explore').click
      expect(page).to have_content("Collection: IIIF Universe")
      expect(page).to have_content("Collections")
      expect(page).not_to have_content("Manifests")
    end
  end

  it "imports an IIIF collection", :js => true do
    visit dashboard_owner_path
    VCR.use_cassette('iiif/cambridge_hebrew_mss') do
      page.find('.tabs').click_link("Start A Project")
      page.fill_in 'at_id', with: @at_id
      find_button('iiif_import').click
      expect(page).to have_content(@at_id)
      expect(page).to have_content("Manifests")
      select("Create Collection", :from => 'manifest_import')
      click_button('Import Checked Manifests')
      expect(page.find('.flash_message')).to have_content("IIIF collection import is processing")
      sleep(15)
      expect(page).to have_content("Works")
      expect(Collection.last.title).to have_content("Hebrew")
      expect(Collection.last.works.count).not_to be_nil
    end
  end
  
  it "checks to allow '.' in IIIF domain URL parameter" do
    visit "iiif/contributions/ac.uk"
    expect(page).to have_content("resources")
    visit "/iiif/contributions/ac.uk/2018-01-01"
    expect(page).to have_content("ac.uk")
    visit "/iiif/contributions/ac.uk/2018-01-01/2019-12-31"
    expect(page).to have_content("ac.uk")
  end
  
  it "tests for transcribed works" do
    col = Collection.where(:title => 'Hebrew Manuscripts').first
    works = col.works
    works.each do |w|
      w.pages.update_all(status: Page::STATUS_TRANSCRIBED, translation_status: Page::STATUS_TRANSLATED)
      w.work_statistic.recalculate
    end
    col.calculate_complete
    col = Collection.where(:title => 'Hebrew Manuscripts').first
    visit collection_path(col.owner, col)
    expect(page).to have_content("All works are fully transcribed")
    page.click_link("Show All")
    expect(page).not_to have_content("All works are fully transcribed")
    expect(page).to have_content(works.first.title)
    page.click_link("Incomplete Works")
    expect(page).to have_content("All works are fully transcribed")
    expect(page).not_to have_content(works.last.title)
  end

  it "cleans up the logfile" do
    col = Collection.last
    log_file = "#{Rails.root}/public/imports/#{col.id}_iiif.log"
    File.delete(log_file)
  end

end
