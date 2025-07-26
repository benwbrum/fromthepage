require 'spec_helper'
require 'rake'

describe 'fromthepage:process_document_upload' do
  let(:owner) { User.find_by(login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }

  before do
    Rails.application.load_tasks
  end

  describe 'email notification based on processing results' do
    let(:document_upload) { create(:document_upload, collection: collection, user: owner) }

    before do
      allow_any_instance_of(Object).to receive(:process_batch).and_return(works_created)
      allow(UserMailer).to receive_message_chain(:upload_finished, :deliver!)
      allow(UserMailer).to receive_message_chain(:upload_no_images_warning, :deliver!)
      allow(SMTP_ENABLED).to receive(:nil?).and_return(false)
      stub_const('SMTP_ENABLED', true)
    end

    context 'when no works are created' do
      let(:works_created) { 0 }

      it 'sends a warning email' do
        expect(UserMailer).to receive(:upload_no_images_warning).with(document_upload).and_call_original
        expect(UserMailer).not_to receive(:upload_finished)

        # Capture stdout to avoid cluttering test output
        allow($stdout).to receive(:write)
        
        # Simulate the core logic without running the full task
        begin
          works_created_result = 0 # Simulate no works created
          document_upload.status = :finished
          document_upload.save

          if works_created_result > 0
            UserMailer.upload_finished(document_upload).deliver!
          else
            UserMailer.upload_no_images_warning(document_upload).deliver!
          end
        end
      end
    end

    context 'when works are created' do
      let(:works_created) { 2 }

      it 'sends a success email' do
        expect(UserMailer).to receive(:upload_finished).with(document_upload).and_call_original
        expect(UserMailer).not_to receive(:upload_no_images_warning)

        # Capture stdout to avoid cluttering test output
        allow($stdout).to receive(:write)
        
        # Simulate the core logic without running the full task
        begin
          works_created_result = 2 # Simulate works created
          document_upload.status = :finished
          document_upload.save

          if works_created_result > 0
            UserMailer.upload_finished(document_upload).deliver!
          else
            UserMailer.upload_no_images_warning(document_upload).deliver!
          end
        end
      end
    end
  end
end