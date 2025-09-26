require 'spec_helper'

describe "FAQ page", type: :feature do
  it "displays browser compatibility help for Safari Avast issue" do
    visit '/faq'
    
    expect(page).to have_content("Frequently Asked Questions")
    expect(page).to have_content("Browser Compatibility Issues")
    expect(page).to have_content("Connection is not private")
    expect(page).to have_content("Safari")
    expect(page).to have_content("Avast")
    expect(page).to have_content("*.fromthepage.com")
    expect(page).to have_link("official Avast support guide")
  end

  it "provides helpful solutions for the connection issue" do
    visit '/faq'
    
    expect(page).to have_content("excluding FromThePage from Avast")
    expect(page).to have_content("Chrome or Firefox")
    expect(page).to have_content("HTTPS scanning feature")
  end
end