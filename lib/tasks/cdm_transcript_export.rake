require 'contentdm_translator'
namespace :fromthepage do 

  desc "Export transcripts for completed works to CONTENTdm"
  task :cdm_transcript_export, [:collection_id] => :environment do |t, args|
    collection_id = args.collection_id.to_i
    collection = Collection.find(collection_id)
    username = ENV['contentdm_username']
    password = ENV['contentdm_password']
    license = ENV['contentdm_license']

    collection.works.joins(:sc_manifest, :work_statistic).each do |work|
      if work.work_statistic.complete >= 99
        print "\tBeginning export of work #{work.id}, '#{work.title}' \n"
        ContentdmTranslator.export_work_to_cdm(work, username, password, license)
        print "Finished export of work #{work.id}, '#{work.title}' \n"
      else
        print "\tSkipping export of uncompleted work #{work.id}, '#{work.title}' \n"
      end
    end

    if SMTP_ENABLED
      begin
        SystemMailer.cdm_sync_finished(collection).deliver!
#        UserMailer.cdm_sync_finished(collection).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end


  end


end