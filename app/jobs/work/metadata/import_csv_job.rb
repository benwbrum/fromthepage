class Work::Metadata::ImportCsvJob < ApplicationJob
  queue_as :default

  def perform(metadata_file_path:, collection_id:, user_id:)
    metadata_file = File.open(metadata_file_path)
    collection = Collection.find(collection_id)
    user = User.find(user_id)

    result = Work::Metadata::ImportCsv.new(
      metadata_file: metadata_file,
      collection: collection
    ).call

    if SMTP_ENABLED
      begin
        UserMailer.metadata_csv_import_finished(user, result).deliver!
      rescue StandardError => e
        # :nocov:
        print "SMTP Failed: Exception: #{e.message}"
        # :nocov:
      end
    end
  ensure
    metadata_file.close
  end
end
