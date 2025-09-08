namespace :fromthepage do
  desc 'Import several CONTENTdm compound objects'
  task :bulk_import_cdm, [ :cdm_bulk_import_id ] => :environment do |t, args|
    bulk_import = CdmBulkImport.find(args.cdm_bulk_import_id.to_i)


    collection_or_set = bulk_import.collection_or_document_set
    if collection_or_set.is_a? DocumentSet
      collection = collection_or_set.collection
      document_set = collection_or_set
    else
      collection = collection_or_set
      document_set = nil
    end

    errors = {}
    cdm_urls = bulk_import.cdm_urls.split(/\s/m)

    cdm_urls.each_with_index do |cdm_url, index|
      begin
        cdm_url.strip!
        print "\n[#{index+1}/#{cdm_urls.count}] attempting #{cdm_url}\n"
        at_id = ContentdmTranslator.cdm_url_to_iiif(cdm_url)
        print "\n[#{index+1}/#{cdm_urls.count}] importing #{at_id}\n"
        sc_manifest = ScManifest.manifest_for_at_id(at_id)
        work = nil
        work = sc_manifest.convert_with_collection(bulk_import.user, collection)
        if document_set
          document_set.works << work
        end
        puts "#{work.title} has been imported"
        unless work.errors.blank?
          error.update(work.errors)
        end
        if ContentdmTranslator.iiif_manifest_is_cdm? at_id
          puts "Updating #{work.title} from CONTENTdm"
          ContentdmTranslator.update_work_from_cdm(work, bulk_import.ocr_correction)
        end
      rescue Exception => e
        puts "#{e.message}"
        errors.store(at_id, e.message)
        #        errors.store(at_id, e.backtrace.join("\n"))
      end
    end
    puts "CONTENTdm bulk import has completed with these errors: \n#{errors.flatten.join("\n")}"


    if SMTP_ENABLED
      begin
        if errors.blank?
          AdminMailer.cdm_bulk_import_succeeded(bulk_import).deliver!
        else
          AdminMailer.cdm_bulk_import_failed(bulk_import, errors).deliver!
        end
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end
  end
end
