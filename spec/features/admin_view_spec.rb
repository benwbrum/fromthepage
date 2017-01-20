require 'spec_helper'

describe "admin actions" do

before :all do
  @user = User.find_by(login: 'julia')
  @password = 'password'
end

  it "looks at admin tabs" do
    login_as(@user, :scope => :user)

    visit admin_path
    click_link('Users')
    expect(page.current_path).to eq '/admin/user_list'
    click_link('Owners')
    expect(page.current_path).to eq '/admin/owner_list'
    click_link('Uploads')
    expect(page.current_path).to eq '/admin/uploads'
    expect(page).to have_content("Upload Details")
    click_link('Errors')
    expect(page.current_path).to eq '/admin/error_list'
    click_link('Logfile')
    expect(page.current_path).to eq '/admin/tail_logfile'
    click_link('Summary')
    expect(page.current_path).to eq admin_path
  end

end