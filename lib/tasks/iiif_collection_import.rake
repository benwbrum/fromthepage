namespace :fromthepage do 

  desc "Import an IIIF collection"
  task :import_iiif_collection, [:manifest_ids, :collection_id, :user_id] => :environment do |t, args|
    #require IIIF::Presentation??
    manifest_ids = args.manifest_ids
    collection_id = args.collection_id
    user_id = args.user_id
    collection = Collection.find_by(id: collection_id)
    user = User.find_by(id: user_id)
    manifest_array = manifest_ids.split(" ")

    puts "manifest_ids were #{manifest_ids.inspect}"
    puts "collection_id is #{collection_id.inspect}"
    puts "manifest_array is #{manifest_array}"

    manifest_array.each do |manifest|
      at_id = manifest
      sc_manifest = ScManifest.manifest_for_at_id(at_id)
      work = nil
      work = sc_manifest.convert_with_collection(user, collection)              
    end
  end



=begin

  desc "Process a document upload"
  task :process_document_upload, [:document_upload_id] => :environment do |t,args|
    require "#{Rails.root}/app/helpers/error_helper"
    include ErrorHelper

    document_upload_id = args.document_upload_id
    print "fetching upload with ID=#{document_upload_id}\n"
    document_upload = DocumentUpload.find document_upload_id
    
    print "found document_upload for \n\tuser=#{document_upload.user.login}, \n\ttarget collection=#{document_upload.collection.title}, \n\tfile=#{document_upload.file}\n"
    
    document_upload.status = DocumentUpload::Status::PROCESSING
    document_upload.save
    
    process_batch(document_upload, File.dirname(document_upload.file.path), document_upload.id.to_s)

    document_upload.status = DocumentUpload::Status::FINISHED
    document_upload.save

    #if the upload processes correctly,
    #remove the uploaded file to prevent filling up the disk
    if document_upload.status = DocumentUpload::Status::FINISHED
      document_upload.remove_file!
      document_upload.save
    end

    if SMTP_ENABLED
      begin
        SystemMailer.upload_succeeded(document_upload).deliver!
        UserMailer.upload_finished(document_upload).deliver!
      rescue StandardError => e
        print "SMTP Failed: Exception: #{e.message}"
      end
    end

  end
=end


  
end