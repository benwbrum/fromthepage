
require 'spec_helper'

describe "collection settings js tasks", :order => :defined do

  it "Deed view displays public deeds" do
    visit collections_list_path
    page.click_link("Show More")
    expect(page).to have_content("Eleanor transcribed page 2 in the work MS_641-642 in CS Pierce collection")
  end
  it "Deed view hides deeds for private collections" do
    visit collections_list_path
    
    csp = Collection.find(1)
    csp.restricted = true
    csp.save

    page.click_link("Show More")
    expect(page).to_not have_content("Eleanor transcribed page 2 in the work MS_641-642 in CS Pierce collection")
    
    # We need to enable transactional fixtures so we don't have to reset this stuff all the time
    csp.restricted = false
    csp.save
  end
  it "Deed view shows deeds to private collections to owners" do
    owner = User.find_by(login: OWNER)
    login_as(owner, :scope => :user)
    
    visit collections_list_path
    
    csp = Collection.find(1)
    csp.restricted = true
    csp.save

    page.click_link("Show More")
    expect(page).to have_content("Eleanor transcribed page 2 in the work MS_641-642 in CS Pierce collection")
    
    # We need to enable transactional fixtures so we don't have to reset this stuff all the time
    csp.restricted = false
    csp.save
  end

end
