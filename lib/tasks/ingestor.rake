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
  IMAGE_FILE_EXTENSIONS = ['jpg', 'JPG', 'jpeg', 'JPEG', 'png', 'PNG']
  IMAGE_FILE_EXTENSIONS_PATTERN = /jpg|JPG|jpeg|JPEG|png|PNG/
  TIFF_FILE_EXTENSIONS_PATTERN = /tif|TIF|tiff|TIFF/

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


  def process_batch(document_upload, path, temp_dir_seed)
    # copy to temp dir
    temp_dir = temp_dir_path(temp_dir_seed)
    copy_to_temp_dir(path, temp_dir)

    # unzip everything
    unzip_tree(temp_dir)
    # extract any pdfs
    unpdf_tree(temp_dir)
    #convert tiffs to jpgs
    untiff_tree(temp_dir)
    # resize files
    compress_tree(temp_dir)
    # ingest
    ingest_tree(document_upload, temp_dir)
    # clean
    clean_tmp_dir(temp_dir)
  end
  
  def clean_tmp_dir(temp_dir)
    print "Removing #{temp_dir}\n"
    FileUtils::rm_r(temp_dir)
  end
  
  def unzip_tree(temp_dir)
    print "unzip_tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*"))
    ls.each do |path|
      print "\tunzip_tree considering #{path}\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        unzip_tree(path) #recurse
      else
        if File.extname(path) == '.ZIP' || File.extname(path) == '.zip'
          print "Found zipfile #{path}\n"
          #unzip and recur
          destination = File.join(File.dirname(path), File.basename(path).sub(File.extname(path),''))
          print "Calling unzip_file(#{path}, #{destination})\n"
          ImageHelper.unzip_file(path, destination)
          unzip_tree(destination)  # recurse
        end
      end
    end
  end
  
  def unpdf_tree(temp_dir)
    print "unpdf_tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*"))
    ls.each do |path|
      print "\tunpdf_tree considering #{path})\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        unpdf_tree(path) #recurse
      else
        if File.extname(path) == '.PDF' || File.extname(path) == '.pdf'
          print "Found pdf #{path}\n"
          #extract 
          destination = ImageHelper.extract_pdf(path)
        end
      end
    end
  end

  def untiff_tree(temp_dir)
    print "convert tiffs from tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*"))
    ls.each do |path|
      print "\tuntiff_tree considering #{path})\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        untiff_tree(path) #recurse
      else
        if File.extname(path).match TIFF_FILE_EXTENSIONS_PATTERN
          print "Found tiff #{path}\n"
          #convert tiff to jpg
          destination = ImageHelper.convert_tiff(path)
        end
      end
    end

  end

  def compress_tree(temp_dir)
    print "compress tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*")).sort
    ls.each do |path|
      print "compress_tree handling #{path})\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        compress_tree(path) #recurse
      else
        if File.extname(path).match IMAGE_FILE_EXTENSIONS_PATTERN
          print "Found image #{path}\n"
          destination = ImageHelper.compress_image(path)
        end
      end
    end    
  end
  
  def ingest_tree(document_upload, temp_dir) 
    print "ingest_tree(#{temp_dir})\n"
    # first process all sub-directories
    ls = Dir.glob(File.join(temp_dir, "*")).sort
    ls.each do |path|
      print "ingest_tree considering #{path})\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        ingest_tree(document_upload, path) #recurse
      end
    end    
    
    # now process this directory if it contains image files
    image_files = Dir.glob(File.join(temp_dir, "*.{"+IMAGE_FILE_EXTENSIONS.join(',')+"}"))
    if image_files.length > 0
      print "Found #{image_files.length} image files in #{temp_dir} -- converting to a work\n"
      convert_to_work(document_upload, temp_dir)
      print "Finished converting files in #{temp_dir} to a work\n"
    end
    print "Finished ingest_tree for #{temp_dir}\n"
    
  end

  WHITELIST =  [
   "title",
   "identifier",
   "description",
   "restrict_scribes",
   "physical_description",
   "document_history",
   "permission_description",
   "location_of_composition",
   "author",
   "transcription_conventions",
   "scribes_can_edit_titles",
   "supports_translation",
   "translation_instructions",
   "pages_are_meaningful",
   "document_set",
   "slug"
  ]

  
  def convert_to_work(document_upload, path)
    print "convert_to_work creating database record for #{path}\n"
    print "\tconvert_to_work owner = #{document_upload.user.login}\n"
    print "\tconvert_to_work collection = #{document_upload.collection.title}\n"
    print "\tconvert_to_work default title = #{File.basename(path).ljust(3,'.')}\n"
    print "\tconvert_to_work looking for metadata.yml in #{File.join(File.dirname(path), 'metadata.yml')}\n"
    
    
    if File.exist? File.join(path, 'metadata.yml')
      yaml = YAML.load_file(File.join(path, 'metadata.yml'))
    elsif File.exist? File.join(path, 'metadata.yaml')
      yaml = YAML.load_file(File.join(path, 'metadata.yaml'))
    else
      print "\tconvert_to_work no metadata.yml file; using default settings\n"
      yaml = nil
    end
          
    print "\tconvert_to_work loaded metadata.yml values \n#{yaml.to_s}\n"
    
#    binding.pry if path == "/tmp/fromthepage_uploads/16/terrell-papers-jpg"
    User.current_user=document_upload.user
    document_sets = []
    if yaml
      yaml.keep_if { |e| WHITELIST.include? e }
      print "\tconvert_to_work whitelisted metadata.yml values \n#{yaml.to_s}\n"
      document_sets = document_sets_from_yaml(yaml, document_upload.collection)
    end
    work = Work.new(yaml)
    work.owner = document_upload.user
    work.collection = document_upload.collection

    work.title = File.basename(path).ljust(3,'.') unless work.title
    work.save!
    
    new_dir_name = File.join(Rails.root,
                             "public",
                             "images",
                             "uploaded",
                             work.id.to_s)
    print "\tconvert_to_work creating #{new_dir_name}\n"
                             
    FileUtils.mkdir_p(new_dir_name)
    IMAGE_FILE_EXTENSIONS.each do |ext|
#      print "\t\tconvert_to_work copying #{File.join(path, "*.#{ext}")} to #{new_dir_name}:\n"
    FileUtils.cp(Dir.glob(File.join(path, "*.#{ext}")), new_dir_name)    
    Dir.glob(File.join(path, "*.#{ext}")).sort.each { |fn| print "\t\t\tcp #{fn} to #{new_dir_name}\n" }      
#      print "\t\tconvert_to_work copied #{File.join(path, "*.#{ext}")} to #{new_dir_name}\n"
    end    

    # at this point, the new dir should have exactly what we want-- only image files that are adequatley compressed.
    ls = Dir.glob(File.join(new_dir_name, "*")).sort
    GC.start
    ls.each_with_index do |image_fn,i|
      page = Page.new
      print "\t\tconvert_to_work created new page\n"
      page.title = "#{i+1}"
      page.base_image = image_fn
      print "\t\tconvert_to_work before Magick call \n"
      image = Magick::ImageList.new(image_fn)
      GC.start
      print "\t\tconvert_to_work calculating base and height \n"
      page.base_height = image.rows
      page.base_width = image.columns
      image = nil
      GC.start
      work.pages << page      
       print "\t\tconvert_to_work added #{image_fn} to work as page #{page.title}, id=#{page.id}\n"
    end
    work.save!
    record_deed(work)
    
    document_sets.each do |ds|
      print "\t\tconvert_to-work adding #{work.title} to document set #{ds.title}"
      ds.works << work
      ds.save!      
    end
    
    print "convert_to_work succeeded for #{work.title}\n"
  end

  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = Deed::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end

  def document_sets_from_yaml(yaml, collection)
    document_sets = []
    if yaml["document_set"] && yaml["document_set"].is_a?(Array)
      yaml["document_set"].each do |set_title|
        ds = collection.document_sets.where(:title => set_title).first
        unless ds
          print "\t\t\tdocument_sets_from_yaml creating document set #{set_title}"
          ds = DocumentSet.new
          ds.title = set_title
          ds.collection = collection
          ds.is_public = !collection.restricted # inherit public setting of parent collection
          ds.owner_user_id = collection.owner_user_id
          ds.save!
        end
        document_sets << ds
      end
      collection.supports_document_sets = true
      collection.save!
    end
    
    document_sets
  end

  
  def temp_dir_path(seed)
    File.join(Dir.tmpdir, 'fromthepage_uploads', seed)    
  end
  
  def copy_to_temp_dir(path, temp_dir)
    print "creating temp directory #{temp_dir}\n"
    FileUtils.mkdir_p(temp_dir)
    print "copying #{File.join(path, '*')} to #{temp_dir}\n"
    FileUtils.cp_r(Dir.glob(File.join(path,"*")), temp_dir)
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
