namespace :fromthepage do 

  desc "Import an IIIF collection"
  task :import_iiif_collection, [:sc_collection_id, :manifest_ids, :collection_id, :user_id, :import_ocr] => :environment do |t, args|
  
    sc_collection = ScCollection.find_by(id: args.sc_collection_id)
    service = find_service(sc_collection.at_id)
    manifest_indices = args.manifest_ids
    collection_id = args.collection_id
    user_id = args.user_id
    import_ocr = ActiveRecord::ConnectionAdapters::Column.value_to_boolean(args.import_ocr)
    collection = Collection.find_by(id: collection_id)
    user = User.find_by(id: user_id)
    manifest_array = manifest_indices.split(" ")
    puts "manifest_indices were #{manifest_indices.inspect}"
    puts "collection_id is #{collection_id.inspect}"
    errors = {}

    service.manifests.each_with_index do |manifest, index|
      if manifest_array.include?(index.to_s)
        begin
          at_id = manifest["@id"]
          puts at_id
          sc_manifest = ScManifest.manifest_for_at_id(at_id)
          work = nil
          work = sc_manifest.convert_with_collection(user, collection)
          puts "#{work.title} has been imported"
          unless work.errors.blank?
            error.update(work.errors)
          end
          if ContentdmTranslator.iiif_manifest_is_cdm? at_id
            puts "Updating #{work.title} from CONTENTdm"
            ContentdmTranslator.update_work_from_cdm(work, import_ocr)
          end
        rescue => e
          puts "#{e.message}"
          errors.store(at_id, e.message)
#          errors.store(at_id, e.backtrace.join("\n"))
        end
      end
    end
    puts "Collection import has completed with these errors: \n#{errors.flatten.join("\n")}"

    if SMTP_ENABLED
      begin
        if errors.blank?
          AdminMailer.iiif_collection_import_succeeded(user_id, collection_id).deliver!
        else
          AdminMailer.iiif_collection_import_failed(user_id, collection_id, errors).deliver!
        end
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end

  end
  
  def find_service(at_id)
    puts "Importing #{at_id}"
    connection = open(at_id)
    manifest_json = connection.read
    service = IIIF::Service.parse(manifest_json)
    return service
  end
  

end