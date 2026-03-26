namespace :fromthepage do
  desc 'Cleans old bulk exports'
  task :clean_bulk_exports, [:days_old] => :environment do |t, args|
    days_old = args.days_old.to_i
    BulkExport.where('created_at < ?', Time.now - days_old.days).each do |export|
      export.clean_zip_file
    end
  end


  desc 'Process a bulk export'
  task :process_bulk_export, [:bulk_export_id] => :environment do |t, args|
    bulk_export_id = args.bulk_export_id
    print "fetching bulk export with ID=#{bulk_export_id}\n"
    bulk_export = BulkExport.find(bulk_export_id)

    BulkExport::ProcessJob.perform_now(
      user_id: bulk_export.user_id,
      bulk_export_id: bulk_export.id
    )
  end
end
