require 'spec_helper'

describe "admin actions" do

  before :all do
    @admin = User.find_by(login: ADMIN)
    @owner = User.find_by(login: OWNER)
  end

  before :each do
      login_as(@admin, :scope => :user)
  end  

  it "looks at admin tabs" do
    user = User.find_by(login: USER)
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
    page.find('.tabs').click_link("Logfile")
    expect(page.current_path).to eq '/admin/tail_logfile'
    page.find('.tabs').click_link("Settings")
    expect(page).to have_content("Edit owner welcome email")
    page.find('.tabs').click_link("Summary")
    expect(page.current_path).to eq admin_path
    expect(page).to have_selector(".counter")
  end

  it "changes email content" do
    visit admin_path
    page.find('.tabs').click_link("Settings")
    expect(page.find('#admin_welcome_text')).to have_content(PageBlock.find_by(view: 'new_owner').html)
    page.fill_in 'admin_welcome_text', with: 'New email text'
    click_button('Save Changes')
    expect(page.find('.flash_message')).to have_content("Admin settings have been updated")
    expect(PageBlock.find_by(view: 'new_owner').html).to eq 'New email text'
  end

  it "makes a user an owner" do
    user2 = User.find_by(login: NEW_OWNER)
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
    user2 = User.find_by(login: NEW_OWNER)
    expect(user2.owner).to be true
  end

  it "logs in as another user" do
    visit admin_path
    page.find('.tabs').click_link("Owners")
    expect(page).to have_content("Owner Login")
    #masquerade as the owner and see permissions
    page.find('tr', text: @owner.login).click_link("Login As")
    expect(page).to have_selector('a', text: 'Undo Login As')
    click_link(I18n.t('dashboard.plain'))
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
    visit admin_path
    expect(page.current_path).to eq dashboard_path

    #un-masquerade and make sure the user is the admin again
    click_link('Undo Login As')
    expect(page).not_to have_selector('a', text: 'Undo Login As')
    expect(page).to have_content @admin.display_name
    expect(page).to have_selector('a', text: 'Admin Dashboard')
    page.find('a', text: 'Admin Dashboard').click
    expect(page).to have_content("Administration")
  end

end