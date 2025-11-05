namespace :fromthepage do
  desc 'Migrate transcription JSON for pages'
  task :migrate_transcription_json, [:start_from_id] => :environment do |_t, args|
    start_from_id = args[:start_from_id].to_i
    start_from_id = 1 if start_from_id.zero?

    collections = Collection.where(id: start_from_id..Float::INFINITY)
                            .where(field_based: true)
                            .order(:id)

    collections.find_each do |collection|
      TranscriptionField::Lib::MigrateHandler.new(collection: collection).perform
    end
  end
end
