require 'contentdm_translator'
namespace :fromthepage do
  desc 'Update a (IIIF-imported) work from the CONTENTdm API'
  task :cdm_work_update, [ :work_id, :import_ocr ] => :environment do |t, args|
    work_id = args.work_id.to_i
    import_ocr = ActiveRecord::Type::Boolean.new.cast(args.import_ocr)
    work = Work.find(work_id)
    collection = work.collection

    print "Beginning update of work ID #{work_id}, '#{work.title}' \n"
    ContentdmTranslator.update_work_from_cdm(work, import_ocr)
    # TODO: This patches CDM imports. It would be good to refactor it into interactor to make testing easier
    Elasticsearch::Collection::SyncJob.perform_now(
      user_id: nil,
      collection_id: collection.id,
      type: collection.is_a?(DocumentSet) ? :document_set : :collection,
      skip_collection: false
    )
    print "Finished update of work ID #{work_id}, '#{work.title}' \n"
  end
end
