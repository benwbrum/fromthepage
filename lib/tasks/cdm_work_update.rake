require 'contentdm_translator'
namespace :fromthepage do 

  desc "Update a (IIIF-imported) work from the CONTENTdm API"
  task :cdm_work_update, [:work_id, :import_ocr] => :environment do |t, args|
    work_id = args.work_id.to_i
    import_ocr = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(args.import_ocr)
    work = Work.find(work_id)  

    print "Beginning update of work ID #{work_id}, '#{work.title}' \n"
    ContentdmTranslator.update_work_from_cdm(work, import_ocr)
    print "Finished update of work ID #{work_id}, '#{work.title}' \n"
  end

end