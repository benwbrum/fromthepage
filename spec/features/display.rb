#this code needs to go into the IIIF-collections spec in the IIIF-collections branch (because it needs an imported collection to work correctly.)  I'm pushing up the code, but commenting it out, and will add it to IIIF collections once it can all be merged together.
=begin
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

  it "tests for transcribed works", :js => true do
    col = Collection.last
    works = col.works
    works.each do |w|
      w.pages.each do |p|
        p.update_columns(status: "transcribed")
      end
      w.work_statistic.recalculate
    end
    visit collection_path(col.owner, col)
    expect(page).to have_content("All works are fully transcribed")
    page.find('a', text: "Click to show transcribed works").click
    expect(page).not_to have_content("All works are fully transcribed")
    expect(page).to have_content(works.first.title)
    page.uncheck('hide_completed')
    expect(page).to have_content("All works are fully transcribed")
    expect(page).not_to have_content(works.first.title)
    page.check('hide_completed')
    expect(page).not_to have_content("All works are fully transcribed")
    expect(page).to have_content(works.first.title)
  end

end
=end