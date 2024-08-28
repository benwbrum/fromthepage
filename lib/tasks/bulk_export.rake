namespace :fromthepage do
  desc "Cleans old bulk exports"
  task :clean_bulk_exports, [:days_old] => :environment do |t,args|
    days_old = args.days_old.to_i
    BulkExport.where("created_at < ?", Time.now - days_old.days).each do |export|
      export.clean_zip_file
    end
  end

  desc "Process a bulk export"
  task :process_bulk_export, [:bulk_export_id] => :environment do |t,args|
    require "#{Rails.root}/app/helpers/error_helper"
    include ErrorHelper
    include Rails.application.routes.url_helpers

    bulk_export_id = args.bulk_export_id
    print "fetching bulk export with ID=#{bulk_export_id}\n"
    bulk_export = BulkExport.find bulk_export_id

    print "found bulk_export for \n\tuser=#{bulk_export.user.login}, \n"
    print "\tfrom collection=#{bulk_export.collection.title}\n" if bulk_export.collection
    pp bulk_export.attributes

    bulk_export.status = BulkExport::Status::PROCESSING
    bulk_export.save

    # process_batch(bulk_export, File.dirname(bulk_export.file.path), bulk_export.id.to_s)
    bulk_export.export_to_zip

    bulk_export.status = :finished
    bulk_export.save


    if SMTP_ENABLED
      begin
        UserMailer.bulk_export_finished(bulk_export).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end
  end

end
