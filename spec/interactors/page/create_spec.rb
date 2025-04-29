require 'spec_helper'

describe Page::Create do
  let(:owner) { User.first }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:work) { create(:work, collection: collection) }

  let(:page_params) { { title: 'New page' } }

  let(:result) do
    described_class.new(work: work, page_params: page_params).call
  end

  it 'creates new page' do
    expect(result.success?).to be_truthy
    expect(result.page).to have_attributes(
      title: 'New page',
      base_image: '',
      work_id: work.id
    )
  end

  context 'with valid image' do
    let(:file_path) { Rails.root.join('test_data/images/pages/sanskrit.jpg') }
    let(:file_type) { 'image/jpeg' }
    let(:page_params) do
      {
        title: 'New page',
        base_image: Rack::Test::UploadedFile.new(file_path, file_type)
      }
    end

    it 'creates new page' do
      expect(result.success?).to be_truthy
      expect(result.page).to have_attributes(
        title: 'New page',
        base_image: Rails.root.join("public/images/working/upload/#{result.page.id}.jpg").to_s,
        work_id: work.id
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

    it 'fails to create new page' do
      expect(result.success?).to be_falsey

      expect(result.page.persisted?).to be_falsey
      expect(result.page.errors).to include(:base_image)
    end
  end
end
