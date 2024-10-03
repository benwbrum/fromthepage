namespace :fromthepage do 

  desc "Import all pages of a IIIF collection"
  task :import_paged_iiif_collection, [:at_id, :collection_id] => :environment do |t, args|
    collection_at_id = args.at_id
    collection_id = args.collection_id.to_i
    collection = Collection.find collection_id
    import_ocr=false

    raw_json = URI.open(collection_at_id).read
    hash = JSON.parse(raw_json)
    manifests=[]
    page_uri = hash['first']
    
    # loop through each sub-page
    while page_uri
      print "fetching collection page #{page_uri}\n"
      raw_json = URI.open(page_uri).read
      hash = JSON.parse(raw_json)
      manifests += hash['manifests']

      # loop through each manifest
      hash['manifests'].each do |manifest|
        begin
          at_id = manifest['@id']
          print "\nattempting item manifest #{at_id}\n"
          sc_manifest = ScManifest.manifest_for_at_id(at_id)
          work = nil
          work = sc_manifest.convert_with_collection(collection.owner, collection, nil, import_ocr)
        rescue => e
          puts "Error importing #{at_id}"
          puts "#{e.message}"
          puts e.backtrace.join("\n")
        end
      end
      page_uri = hash['next']
    end    
  end

  desc "Import an IIIF collection"
  task :import_iiif_collection, [:sc_collection_id, :manifest_ids, :collection_id, :user_id, :import_ocr] => :environment do |t, args|
  
    sc_collection = ScCollection.find_by(id: args.sc_collection_id)
    manifest_indices = args.manifest_ids
    collection_id = args.collection_id
    user_id = args.user_id
    import_ocr = ActiveRecord::Type::Boolean.new.cast(args.import_ocr)
    document_set = nil

    if md=collection_id.match(/D(\d+)/)
      document_set = DocumentSet.find_by(id: md[1])
      collection = document_set.collection
    else
      collection = Collection.find_by(id: collection_id)
    end
    user = User.find_by(id: user_id)
    manifest_array = manifest_indices.split(" ")
    puts "manifest_indices were #{manifest_indices.inspect}"
    puts "collection_id is #{collection_id.inspect}"
    errors = {}

    if sc_collection.v3?
      sc_collection.v3_hash = fetch_manifest(sc_collection.at_id)
    else
      sc_collection.service = fetch_service(sc_collection.at_id)
    end

    sc_collection.manifests.each_with_index do |manifest, index|
      if manifest_array.include?(index.to_s)
        begin
          at_id = manifest["@id"] || manifest['id']
          print "\n[#{index}/#{sc_collection.manifests.count}] attempting #{at_id}\n"
          if sc_collection.v3?
            # TODO
            sc_manifest = ScManifest.manifest_for_v3_hash(fetch_manifest(at_id)) # fetch the manifest
          else
            sc_manifest = ScManifest.manifest_for_at_id(at_id)
          end
          work = nil
          work = sc_manifest.convert_with_collection(user, collection, nil, import_ocr)
          if document_set
            document_set.works << work
          end
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
          puts e.backtrace.join("\n")
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
  
  def fetch_service(at_id)
    IIIF::Service.parse(fetch_raw(at_id))
  end
  

  def fetch_manifest(at_id)
    JSON.parse(fetch_raw(at_id))
  end

  def fetch_raw(at_id)
    puts "Importing #{at_id}"
    connection = URI.open(at_id)
    manifest_json = connection.read

    manifest_json
  end

end
