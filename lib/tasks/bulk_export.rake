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
    # print "fetching bulk export with ID=#{bulk_export_id}\n"
    bulk_export = BulkExport.find(bulk_export_id)

    bulk_export.update!(status: :queued)

    result = BulkExport::Process.new(bulk_export: bulk_export).call

    raise result.full_errors unless result.success?

    # TODO: Once solid_queue worker contexts are figured out, bring this back
    # BulkExport::ProcessJob.perform_now(
    #   user_id: bulk_export.user_id,
    #   bulk_export_id: bulk_export.id
    # )
  end

  # NOTE: This is temporary
  desc 'Process a bulk export thru job'
  task :process_bulk_export_job, [:bulk_export_id] => :environment do |t, args|
    bulk_export_id = args.bulk_export_id
    bulk_export = BulkExport.find(bulk_export_id)

    bulk_export.update!(status: :queued)

    BulkExport::ProcessJob.perform_later(
      user_id: bulk_export.user_id,
      bulk_export_id: bulk_export.id
    )
  end
end
