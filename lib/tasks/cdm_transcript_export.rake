require 'contentdm_translator'
namespace :fromthepage do
  desc 'Export transcripts for completed works to CONTENTdm'
  task :cdm_transcript_export, [:target_slug] => :environment do |t, args|
    sync_target = Collection.friendly.find(args.target_slug, allow_nil: true) || DocumentSet.friendly.find(args.target_slug)
    collection = sync_target.is_a?(DocumentSet) ? sync_target.collection : sync_target
    username = ENV['contentdm_username']
    password = ENV['contentdm_password']
    license = ENV['contentdm_license']

    include_ai_drafts = collection.cdm_export_setting&.transcript_source == CdmExportSetting::HUMAN_AND_AI

    sync_target.works.joins(:sc_manifest, :work_statistic).each do |work|
      if include_ai_drafts || work.work_statistic.complete >= 99
        print "\tBeginning export of work #{work.id}, '#{work.title}' \n"
        ContentdmTranslator.export_work_to_cdm_with_retry(work, username, password, license)
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
