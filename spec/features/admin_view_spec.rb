require 'spec_helper'

RSpec.describe 'admin actions' do
  let(:admin) { create(:unique_user, :admin, :owner, display_name: 'Spec Admin') }
  let(:owner) { create(:unique_user, :owner) }
  let(:user) { create(:unique_user) }
  let(:new_owner) { create(:unique_user) }

  before do
    DatabaseCleaner.start
    Capybara.reset_sessions!
    create_admin_page_blocks
    login_as(admin, scope: :user)
  end

  after do
    Capybara.reset_sessions!
    DatabaseCleaner.clean
  end

  it 'looks at admin tabs' do
    user
    owner

    visit admin_path
    page.find('.tabs').click_link('Users')
    expect(page.current_path).to eq '/admin/user_list'
    expect(page).to have_content('User Login')
    expect(page).to have_content user.login
    page.find('.tabs').click_link('Abuse')
    expect(page.current_path).to eq '/admin/flag_list'
    page.find('.tabs').click_link('Owners')
    expect(page.current_path).to eq '/admin/owner_list'
    expect(page).to have_content('Owner Login')
    expect(page).to have_content owner.login
    expect(page).not_to have_content user.login
    page.find('.tabs').click_link('Uploads')
    expect(page.current_path).to eq '/admin/uploads'
    expect(page).to have_content('Upload Details')
    page.find('.tabs').click_link('Logfile')
    expect(page.current_path).to eq '/admin/tail_logfile'
    page.find('.tabs').click_link('Settings')
    expect(page).to have_content('welcome email text')
    page.find('.tabs').click_link('Summary')
    expect(page.current_path).to eq admin_path
    expect(page).to have_selector('.counter')
  end

  it 'changes email content' do
    visit admin_path
    page.find('.tabs').click_link('Settings')
    expect(page.find('#admin_welcome_text')).to have_content("Congratulations! You're now a project owner in FromThePage!")
    page.fill_in 'admin_welcome_text', with: 'New email text'
    click_button('Save Changes')
    expect(page.find('.flash_message')).to have_content('Admin settings have been updated')
    expect(PageBlock.find_by(view: 'new_owner').html).to eq 'New email text'
  end

  it 'makes a user an owner' do
    visit admin_path
    page.find('.tabs').click_link('Users')
    expect(page).to have_content('User Login')
    page.find('tr', text: new_owner.login).click_link('Edit')
    check('user_owner')
    click_button('Save Changes')
    visit admin_path
    page.find('.tabs').click_link('Owners')
    expect(page).to have_content('Owner Login')
    expect(page).to have_content(new_owner.login)
    expect(new_owner.reload.owner).to be true
  end

  it 'logs in as another user' do
    collection = create(:collection, owner_user_id: owner.id)

    visit admin_path
    page.find('.tabs').click_link('Owners')
    expect(page).to have_content('Owner Login')
    page.find('tr', text: owner.login).click_link('Login As')
    expect(page).to have_selector('a', text: 'Undo Login As')
    click_link(I18n.t('dashboard.plain'))
    expect(page).to have_content('Owner Dashboard')
    expect(page).to have_content(collection.title)
    work_count = collection.works.count.zero? ? 'no works' : "#{collection.works.count} works"
    expect(page).to have_content(work_count)
    expect(page).to have_selector('a', text: 'Owner Dashboard')
    expect(page).not_to have_selector('a', text: 'Admin Dashboard')
    visit admin_path
    expect(page.current_path).to eq collections_list_path

    click_link('Undo Login As')
    expect(page).not_to have_selector('a', text: 'Undo Login As')
    expect(page).to have_content admin.display_name
    expect(page).to have_selector('a', text: 'Admin Dashboard')
    page.find('a', text: 'Admin Dashboard').click
    expect(page).to have_content('Administration')
  end

  it 'sorts owner list' do
    owner.update!(account_type: 'Large Institution', start_date: 2.days.ago, paid_date: 1.month.from_now)
    admin.update!(account_type: 'Individual Researcher', start_date: 1.day.ago, paid_date: 2.months.from_now)

    visit admin_path
    page.find('.tabs').click_link('Owners')
    expect(page).to have_content('Owner Login')
    click_link('Acct Type')
    expect(page.current_url).to include('sort=account_type')
    expect(page).to have_content(admin.login)
    expect(page).to have_content(owner.login)
    click_link('Acct Expiration')
    expect(page.current_url).to include('sort=paid_date')
    click_link('Start Date')
    expect(page.current_url).to include('sort=start_date')
  end

  it 'searches user list' do
    visit admin_path
    page.find('.tabs').click_link('Users')
    page.fill_in 'search', with: new_owner.email
    click_button('Search')
    expect(page).to have_content(new_owner.email)
    page.fill_in 'search', with: new_owner.login
    click_button('Search')
    expect(page).to have_content(new_owner.email)
    page.fill_in 'search', with: new_owner.display_name
    click_button('Search')
    expect(page).to have_content(new_owner.email)
  end

  it 'downgrades a user' do
    downgraded_user = create(:unique_user, :owner)

    visit admin_path
    page.find('.tabs').click_link('Users')
    visit admin_edit_user_path(user_id: downgraded_user.id)
    page.find('.aright').click_link('Downgrade')
    expect(page).to have_content('User downgraded successfully')
    expect(downgraded_user.reload.owner).to be false
  end

  it "can't access owner dashboard as a downgraded user" do
    downgraded_user = create(:unique_user, :owner)
    downgraded_user.downgrade

    login_as(downgraded_user, scope: :user)
    visit '/dashboard/owner'
    expect(page).not_to have_content('Owner Dashboard')
  end

  it "can't create a collection as a downgraded user" do
    downgraded_user = create(:unique_user, :owner)
    downgraded_user.downgrade

    login_as(downgraded_user, scope: :user)
    visit '/dashboard/startproject'
    expect(page).not_to have_link('Create a Collection')
  end

  it "can't access downgraded user's collections as a non-logged in user" do
    downgraded_user = create(:unique_user, :owner)
    downgraded_user.downgrade

    logout
    visit downgraded_user.slug
    expect(page).not_to have_css('div.collections')
  end

  def create_admin_page_blocks
    PageBlock.find_or_create_by!(view: 'new_owner') do |block|
      block.html = "Congratulations! You're now a project owner in FromThePage!"
    end.update!(html: "Congratulations! You're now a project owner in FromThePage!")

    PageBlock.find_or_create_by!(view: 'flag_denylist') do |block|
      block.html = ''
    end
  end
end
