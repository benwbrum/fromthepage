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

    context 'when source page has uploaded image file (legacy)' do
      let(:source_page) { create(:page, :with_legacy_image, work: source_work) }
      let(:target_work) { create(:work, collection: target_collection, owner_user_id: owner.id) }
      let(:target_page) { create(:page, work: target_work) }

      it 'copies the base image file to active_storage' do
        # Call the helper method directly
        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        expect(target_page.image.attached?).to be_truthy
      end
    end

    context 'when source page has uploaded image file' do
      let(:source_page) { create(:page, :with_image, work: source_work) }
      let(:target_work) { create(:work, collection: target_collection, owner_user_id: owner.id) }
      let(:target_page) { create(:page, work: target_work) }

      it 'copies the base image file to active_storage' do
        # Call the helper method directly
        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        expect(target_page.image.attached?).to be_truthy
      end
    end

    context 'when source page has no base_image' do
      let(:source_page) { create(:page, work: source_work) }
      let(:target_work) { create(:work, collection: target_collection, owner_user_id: owner.id) }
      let(:target_page) { create(:page, work: target_work) }

      it 'does not attempt to copy files' do
        original_base_image = target_page.base_image

        CollectionCopyHelper.copy_page_image_files(source_page, target_page)

        target_page.reload

        # Base image should not be changed
        expect(target_page.image.attached?).to be_falsey
      end
    end
  end
end
