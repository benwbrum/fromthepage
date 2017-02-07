require 'spec_helper'

describe "admin actions" do

before :all do
  @admin = User.find_by(login: 'julia')
  @owner = User.find_by(login: 'margaret')

end

  it "looks at admin tabs" do
    login_as(@admin, :scope => :user)
    user = User.find_by(login: 'eleanor')
    #click on each tab in the admin dashboard
    visit admin_path
    page.find('.tabs').click_link("Users")
    expect(page.current_path).to eq '/admin/user_list'
    expect(page).to have_content("User Login")
    expect(page).to have_content user.login
    page.find('.tabs').click_link("Owners")
    expect(page.current_path).to eq '/admin/owner_list'
    expect(page).to have_content("Owner Login")
    expect(page).to have_content @owner.login
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

  it "logs in as another user" do
    login_as(@admin, :scope => :user)
    visit admin_path
    page.find('.tabs').click_link("Owners")
    expect(page).to have_content("Owner Login")
    #masquerade as the owner and see permissions
    page.find('tr', text: @owner.login).click_link("Login As")
    expect(page).to have_selector('a', text: 'Undo Login As')
    click_link('Dashboard')
    #check the owner dashboard for correct contents
    expect(page).to have_content("Owner Dashboard")
    collections = Collection.where(owner_user_id: @owner.id)
    collections.each do |c|
      expect(page).to have_content(c.title)
      c.works.each do |w|
        expect(page).to have_content(w.title)
      end
    end
    #make the masqueraded user doesn't have access to the admin dashboard
    expect(page).to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')
    #un-masquerade and make sure the user is the admin again
    click_link('Undo Login As')
    expect(page).not_to have_selector('a', text: 'Undo Login As')
    expect(page).to have_content @admin.display_name
    expect(page).to have_selector('a', text: 'Admin Dashboard')
    page.find('a', text: 'Admin Dashboard').click
    expect(page).to have_content("Administration")

  end

end