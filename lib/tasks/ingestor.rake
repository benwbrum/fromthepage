require 'image_helper'
require 'open-uri' # TODO: Move elsewhere

namespace :fromthepage do

  desc "Resize image file or directories of image files"
  task :compress_images, [:pathname] => :environment  do  |t,args|
    pathname = args.pathname
    p "compressing #{pathname}"
    
    if Dir.exist? pathname
      ImageHelper.compress_files_in_dir(pathname)
    else
      # this is a single file
      ImageHelper.compress_file(pathname)
    end
  end


  desc "Import IIIF Collection"
  task :import_iiif, [:collection_url] => :environment  do  |t,args|
      
    ScCollection.delete_all
    ScManifest.delete_all
    ScCanvas.delete_all      
      
    collection_url = args.collection_url
    p "importing #{collection_url}"
    collection_string = ""
    collection_string = open(collection_url).read    

    collection_hash = JSON.parse(collection_string)
    sc_collection = ScCollection.new
    sc_collection.context = collection_hash["@context"]
    sc_collection.save!
    
    collection_hash["manifests"].each do |manifest_item|
      sc_manifest = ScManifest.new
      sc_manifest.sc_collection = sc_collection
      sc_manifest.sc_id = manifest_item["@id"]
      sc_manifest.label = manifest_item["label"]
      
      sc_manifest.save!
      
      print "Ingesting manifest #{sc_manifest.sc_id}\n"
      begin
        manifest_string = open(sc_manifest.sc_id).read
        manifest_hash = JSON.parse(manifest_string)
        
        sc_manifest.metadata = manifest_hash["metadata"].to_json if manifest_hash["metadata"]
        
        first_sequence = manifest_hash["sequences"].first
        sc_manifest.first_sequence_id = first_sequence["@id"]
        sc_manifest.first_sequence_label = first_sequence["label"]
        
        sc_manifest.save!
        
        first_sequence["canvases"].each do |canvas|
          sc_canvas = ScCanvas.new
          sc_canvas.sc_manifest = sc_manifest
          
          sc_canvas.sc_id = canvas["@id"]
          sc_canvas.sc_canvas_id = canvas["@id"]
          sc_canvas.sc_canvas_label = canvas["label"]
          sc_canvas.sc_canvas_width = canvas["width"]
          sc_canvas.sc_canvas_height = canvas["height"]
          
          first_image = canvas["images"].first
          sc_canvas.sc_image_motivation = first_image["motivation"]
          sc_canvas.sc_image_on = first_image["on"]
          
          resource = first_image["resource"]
          sc_canvas.sc_resource_id = resource["@id"]
          sc_canvas.sc_resource_type = resource["@type"]
          sc_canvas.sc_resource_format = resource["format"]
  
          service = resource["service"]
          sc_canvas.sc_service_id = service["@id"]
          sc_canvas.sc_service_context = service["@context"]
          sc_canvas.sc_service_profile = service["profile"]
          
          sc_canvas.save!
        
        end
      rescue OpenURI::HTTPError
        print "WARNING:\tHTTP error accessing manifest #{sc_manifest.sc_id}\n"
      end

    end    
  end

end