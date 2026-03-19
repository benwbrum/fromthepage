require 'spec_helper'
require 'csv'

describe Work::Metadata::ImportCsvJob do
  include ActiveJob::TestHelper

  before do
    Current.user = owner
    allow(Settings.active_job).to receive(:attempts).and_return(1)
  end

  subject(:worker) { described_class.new }

  let(:owner) { User.find_by(login: OWNER) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let(:headers) do
    [
      'FromThePage Title',
      '*Collection*',
      '*Uploaded Filename*',
      '*FromThePage ID*',
      'FromThePage Description',
      'Identifier'
    ]
  end
  let(:rows) do
    [
      [work.title, work.collection.title, '', work.id, work.description, work.identifier]
    ]
  end
  let(:metadata_file_path) do
    csv_data = CSV.generate(headers: true) do |csv|
      csv << headers
      rows.each do |row|
        csv << row
      end
    end
    temp_file = Tempfile.new(['metadata', '.csv'])
    temp_file.write(csv_data)
    temp_file.rewind

    temp_file.path
  end

  let(:perform_worker) do
    worker.perform(
      metadata_file_path: metadata_file_path,
      collection_id: collection.reload.id,
      user_id: owner.id
    )
  end

  context 'without errors' do
    it 'performs job' do
      ActionMailer::Base.deliveries.clear

      perform_enqueued_jobs do
        perform_worker
      end

      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.first.to).to include owner.email
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        I18n.t('user_mailer.metadata_csv_import_finished.subject')
      )
      expect(ActionMailer::Base.deliveries.first.body.encoded).to match(
        I18n.t('user_mailer.metadata_csv_import_finished.success', count: 1)
      )
    end
  end

  context 'with errors' do
    let(:rows) do
      [
        [work.title, work.collection.title, '', work.id, work.description, work.identifier],
        ['missing', 'missing', 'missing', 'missing', 'missing', 'missing']
      ]
    end

    it 'performs job' do
      ActionMailer::Base.deliveries.clear

      expect do
        perform_enqueued_jobs do
          described_class.perform_later(
            metadata_file_path: metadata_file_path,
            collection_id: collection.reload.id,
            user_id: owner.id
          )
        end
      end.to raise_error(Minitest::UnexpectedError) { |error|
          expect(error.error.message).to match(/Import metadata finished with errors/)
        }

      expect(ActionMailer::Base.deliveries).not_to be_empty
      expect(ActionMailer::Base.deliveries.first.to).to include owner.email
      expect(ActionMailer::Base.deliveries.first.subject).to eq(
        I18n.t('user_mailer.metadata_csv_import_finished.subject')
      )
      expect(ActionMailer::Base.deliveries.first.body.encoded).to match(
        I18n.t('user_mailer.metadata_csv_import_finished.fail', count: 1, error_count: 1)
      )
    end
  end
end
