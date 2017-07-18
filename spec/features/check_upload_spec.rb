require 'spec_helper'

describe "check for successful data upload" do

  before :all do
    @owner = User.find_by(login: OWNER)
  end

  it "checks that the file has been uploaded" do
    login_as(@owner, :scope => :user)
    sleep(60)
    @work = Work.find_by(title: 'test')
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    expect(page).to have_content(@work.pages.first.title)
    click_link(@work.pages.first.title)
    page.find('#page_source_text')
    expect(page).to have_button('Preview')
  end

end