require 'spec_helper'

describe "admin actions" do

before :all do
  @admin = User.find_by(login: 'julia')
end

  it "looks at admin tabs" do
    login_as(@admin, :scope => :user)
    user = User.find_by(login: 'eleanor')
    owner = User.find_by(login: 'margaret')
    #click on each tab in the admin dashboard
    visit admin_path
    page.find('.tabs').click_link("Users")
    expect(page.current_path).to eq '/admin/user_list'
    expect(page).to have_content("User Login")
    expect(page).to have_content user.login
    page.find('.tabs').click_link("Owners")
    expect(page.current_path).to eq '/admin/owner_list'
    expect(page).to have_content("Owner Login")
    expect(page).to have_content owner.login
    expect(page).not_to have_content user.login
    page.find('.tabs').click_link("Uploads")
    expect(page.current_path).to eq '/admin/uploads'
    expect(page).to have_content("Upload Details")
    page.find('.tabs').click_link("Errors")
    expect(page.current_path).to eq '/admin/error_list'
    expect(page).to have_content("User & Context")
    page.find('.tabs').click_link("Logfile")
    expect(page.current_path).to eq '/admin/tail_logfile'
    page.find('.tabs').click_link("Summary")
    expect(page.current_path).to eq admin_path
    expect(page).to have_selector(".counter")
  end

  it "makes a user an owner" do
    login_as(@admin, :scope => :user)
    user2 = User.find_by(login: 'harry')
    visit admin_path
    page.find('.tabs').click_link("Users")
    expect(page).to have_content("User Login")
    page.find('tr', text: user2.login).click_link("Edit")
    check('user_owner')
    click_button('Save Changes')
    visit admin_path
    page.find('.tabs').click_link("Owners")
    expect(page).to have_content("Owner Login")
    expect(page).to have_content(user2.login)
    user2 = User.find_by(login: 'harry')
    expect(user2.owner).to be true
  end

end