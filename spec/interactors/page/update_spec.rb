require 'spec_helper'

describe Page::Update do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }
  let(:work_statistic) { create(:work_statistic, work: work) }
  let!(:page) { create(:page, :with_image, title: 'Original title', work: work, status: :blank) }
  let(:page_params) { { title: 'Updated title', status: :new, translation_status: :new } }

  let(:result) do
    described_class.new(page: page, page_params: page_params).call
  end

  it 'updates page' do
    expect(result.success?).to be_truthy
    expect(result.page).to have_attributes(
      title: 'Updated title',
      work_id: work.id,
      status: 'new',
      translation_status: 'new'
    )
  end

  context 'with valid image' do
    let(:file_path) { Rails.root.join('test_data/images/pages/sanskrit.jpg') }
    let(:file_type) { 'image/jpeg' }
    let(:page_params) do
      {
        title: 'Updated title',
        base_image: Rack::Test::UploadedFile.new(file_path, file_type)
      }
    end

    it 'updates page' do
      expect(result.success?).to be_truthy
      expect(result.page).to have_attributes(
        title: 'Updated title',
        base_image: Rails.root.join("public/images/working/upload/#{result.page.id}.jpg").to_s,
        work_id: work.id,
        status: 'new',
        translation_status: 'new'
      )
    end
  end

  context 'with invalid image' do
    let(:file_path) { Rails.root.join('test_data/transcripts/sanskrit.txt') }
    let(:file_type) { 'text/plain' }
    let(:page_params) do
      {
        title: 'New page',
        base_image: Rack::Test::UploadedFile.new(file_path, file_type)
      }
    end

    it 'fails to update page' do
      expect(result.success?).to be_falsey

      expect(result.page.errors).to include(:base_image)
    end
  end
end
