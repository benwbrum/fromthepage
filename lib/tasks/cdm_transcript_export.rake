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
        print "Beginning export of work #{work.id}, '#{work.title}' \n"
        ContentdmTranslator.export_work_to_cdm(work, username, password, license)
        print "Finished export of work #{work.id}, '#{work.title}' \n"
      else
        print "Skipping export of uncompleted work #{work.id}, '#{work.title}' \n"
      end
    end
  end

end