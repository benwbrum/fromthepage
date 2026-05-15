require 'spec_helper'

RSpec.describe SystemMailer, type: :mailer do
  describe '#cdm_sync_finished' do
    let(:owner) { create(:owner) }
    let(:staff) { create(:user) }
    let(:collection) { create(:collection, owner_user_id: owner.id) }

    context 'when collection has an owner and staff members' do
      before do
        allow(ContentdmTranslator).to receive(:log_contents).and_return('sync log output')
        collection.owners << staff
      end

      it 'sends a single email to all recipients' do
        mail = SystemMailer.cdm_sync_finished(collection)
        expect(mail.to).to include(owner.email)
        expect(mail.to).to include(staff.email)
      end

      it 'has the correct subject' do
        mail = SystemMailer.cdm_sync_finished(collection)
        expect(mail.subject).to eq("CONTENTdm Sync Finished for  #{collection.title}")
      end
    end

    context 'when collection has no primary owner (owner_user_id is nil)' do
      let(:collection_without_owner) { create(:collection, owner_user_id: nil) }

      before do
        allow(ContentdmTranslator).to receive(:log_contents).and_return('sync log output')
        collection_without_owner.owners << staff
      end

      it 'does not raise an error' do
        expect { SystemMailer.cdm_sync_finished(collection_without_owner) }.not_to raise_error
      end

      it 'still sends email to staff owners' do
        mail = SystemMailer.cdm_sync_finished(collection_without_owner)
        expect(mail.to).to include(staff.email)
      end
    end

    context 'when collection has only a primary owner and no staff' do
      before do
        allow(ContentdmTranslator).to receive(:log_contents).and_return('sync log output')
      end

      it 'sends email to the primary owner' do
        mail = SystemMailer.cdm_sync_finished(collection)
        expect(mail.to).to include(owner.email)
      end
    end

    context 'when sync log contains failures' do
      before do
        allow(ContentdmTranslator).to receive(:log_contents).and_return('2 failed uploads')
      end

      it 'uses a failure subject' do
        mail = SystemMailer.cdm_sync_finished(collection)
        expect(mail.subject).to eq("CONTENTdm Sync Finished with Failures for  #{collection.title}")
      end
    end
  end
end
