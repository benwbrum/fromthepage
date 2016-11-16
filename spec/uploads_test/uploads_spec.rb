require 'spec_helper'

describe "check uploads" do

  before :all do

    @user = User.find_by(login: 'minerva')
    @work = Work.find_by(title: 'test')
  end

  it "checks that the file has been uploaded" do
    visit "/display/read_work?work_id=#{@work.id}"
    expect(page).to have_content(@work.title)
    expect(page).to have_content(@work.pages.first.title)
    click_link(@work.pages.first.title)
    expect(page).to have_content('This page is not transcribed')
  end

end
