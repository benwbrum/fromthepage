require 'spec_helper'
require 'rake'
require 'fileutils'

RSpec.describe 'Collection Copy Rake Task' do
  before(:all) do
    Rake.application.rake_require 'tasks/collection_copy'
    Rake::Task.define_task(:environment)
  end

  let!(:owner) { create(:unique_user, :owner) }
  let(:source_collection) { create(:collection, owner_user_id: owner.id) }
  let(:target_collection) { create(:collection, owner_user_id: owner.id) }
  let(:source_work) { create(:work, collection: source_collection, owner_user_id: owner.id) }

  describe 'copy_page_image_files' do
    let(:task) { Rake::Task['fromthepage:copy:collection'] }

    context 'when source page has uploaded image file' do
      let(:source_page) { create(:page, work: source_work) }
      let(:target_work) { create(:work, collection: target_collection, owner_user_id: owner.id) }
      let(:target_page) { create(:page, work: target_work) }

      before do
        # Create a test image file for the source page
        source_image_path = File.join(Rails.root, 'public', 'images', 'working', 'upload', "#{source_page.id}.jpg")
        FileUtils.mkdir_p(File.dirname(source_image_path))

        # Copy test image from test_data
        test_image = File.join(Rails.root, 'test_data', 'images', 'pages', 'sanskrit.jpg')
        FileUtils.cp(test_image, source_image_path) if File.exist?(test_image)

        source_page.update_column(:base_image, source_image_path)
      end

      after do
        # Clean up test files
        [source_page, target_page].each do |page|
          next unless page.base_image.present?

          image_path = File.join(Rails.root, 'public', page.base_image.sub(/.*public/, ''))
          File.delete(image_path) if File.exist?(image_path)

          thumb_path = page.thumbnail_filename
          File.delete(thumb_path) if thumb_path.present? && File.exist?(thumb_path)
        end
      end

      it 'copies the base image file to a new location' do
        # Call the helper method directly
        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        # Verify target page has different image path
        expect(target_page.base_image).not_to eq(source_page.base_image)
        expect(target_page.base_image).to include(target_page.id.to_s)

        # Verify target image file exists
        target_image_path = File.join(Rails.root, 'public', target_page.base_image.sub(/.*public/, ''))
        expect(File.exist?(target_image_path)).to be true

        # Verify source image still exists
        source_image_path = File.join(Rails.root, 'public', source_page.base_image.sub(/.*public/, ''))
        expect(File.exist?(source_image_path)).to be true
      end

      it 'does not share image files between source and target' do
        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        source_image_path = File.join(Rails.root, 'public', source_page.base_image.sub(/.*public/, ''))
        target_image_path = File.join(Rails.root, 'public', target_page.base_image.sub(/.*public/, ''))

        # Files should be different
        expect(source_image_path).not_to eq(target_image_path)

        # Deleting target should not affect source
        File.delete(target_image_path) if File.exist?(target_image_path)
        expect(File.exist?(source_image_path)).to be true
      end
    end

    context 'when source page has no base_image' do
      let(:source_page) { create(:page, work: source_work, base_image: nil) }
      let(:target_work) { create(:work, collection: target_collection, owner_user_id: owner.id) }
      let(:target_page) { create(:page, work: target_work) }

      it 'does not attempt to copy files' do
        original_base_image = target_page.base_image

        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        # Base image should not be changed
        expect(target_page.base_image).to eq(original_base_image)
      end
    end
  end
end
