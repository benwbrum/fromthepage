require 'spec_helper'

describe 'check for successful data upload' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) do
    create(:work, title: 'test', owner: owner, owner_user_id: owner.id, collection: collection)
  end
  let(:uploaded_page) { create(:page, title: 'Uploaded Test Page', work: work) }

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  it 'checks that the file has been uploaded' do
    uploaded_page

    login_as(owner, scope: :user)
    visit collection_read_work_path(owner, collection, work)

    expect(page).to have_content(work.title)
    expect(page).to have_content(uploaded_page.title)
  end
end
