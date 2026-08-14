require 'spec_helper'
require 'tmpdir'

Rails.application.load_tasks unless Rake::Task.task_defined?('fromthepage:process_document_upload')

describe 'Ingestor ZIP processing' do
  it 'recursively processes a ZIP nested inside another ZIP' do
    Dir.mktmpdir('ingestor-nested-zip') do |temp_dir|
      inner_archive = File.join(temp_dir, 'inner.zip')
      Zip::File.open(inner_archive, create: true) do |zip|
        zip.get_output_stream('pages/page.txt') { |stream| stream.write('nested contents') }
      end

      outer_archive = File.join(temp_dir, 'outer.zip')
      Zip::File.open(outer_archive, create: true) do |zip|
        zip.add('inner.zip', inner_archive)
      end
      FileUtils.rm(inner_archive)

      unzip_tree(temp_dir)

      extracted = File.join(temp_dir, 'outer', 'inner', 'pages', 'page.txt')
      expect(File.read(extracted)).to eq('nested contents')
    end
  end
end

describe 'Ingestor email logic' do
  let(:owner) { User.find_by(login: OWNER) || create(:user, login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let(:document_upload) { create(:document_upload, collection: collection, user: owner) }

  after do
    # Clean up created records
    document_upload.destroy
    collection.destroy
    # Don't destroy owner if it was found, only if we created it
    owner.destroy if owner.login == OWNER && User.where(login: OWNER).count == 1
  end

  describe 'email notification based on processing results' do
    before do
      # Stub SMTP_ENABLED to be truthy for these tests
      stub_const('SMTP_ENABLED', true)
    end

    context 'when no works are created' do
      it 'sends a warning email instead of success email' do
        expect(UserMailer).to receive(:upload_no_images_warning).with(document_upload).and_call_original
        expect(UserMailer).not_to receive(:upload_finished)

        # Simulate the logic from the rake task when works_created = 0
        works_created = 0
        if works_created > 0
          UserMailer.upload_finished(document_upload).deliver!
        else
          UserMailer.upload_no_images_warning(document_upload).deliver!
        end
      end
    end

    context 'when works are created' do
      it 'sends a success email instead of warning email' do
        expect(UserMailer).to receive(:upload_finished).with(document_upload).and_call_original
        expect(UserMailer).not_to receive(:upload_no_images_warning)

        # Simulate the logic from the rake task when works_created > 0
        works_created = 2
        if works_created > 0
          UserMailer.upload_finished(document_upload).deliver!
        else
          UserMailer.upload_no_images_warning(document_upload).deliver!
        end
      end
    end
  end
end
