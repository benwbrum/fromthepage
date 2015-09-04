require 'image_helper'

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

  desc "Process a document upload"
  task :process_document_upload, [:document_upload_id] => :environment do |t,args|
    document_upload_id = args.document_upload_id
    print "fetching upload with ID=#{document_upload_id}\n"
    document_upload = DocumentUpload.find document_upload_id
    
    print "found document_upload for \n\tuser=#{document_upload.user.login}, \n\ttarget collection=#{document_upload.collection.title}, \n\tfile=#{document_upload.file}\n"
    
    process_batch(document_upload, File.dirname(document_upload.file.path), document_upload.id.to_s)
  end


  def process_batch(document_upload, path, temp_dir_seed)
    # copy to temp dir
    temp_dir = temp_dir_path(temp_dir_seed)
    copy_to_temp_dir(path, temp_dir)

    # unzip everything
    unzip_tree(temp_dir)
    # extract any pdfs
    unpdf_tree(temp_dir)
    # resize files
    compress_tree(temp_dir)
    # ingest
    ingest_tree(document_upload, temp_dir)
  end
  
  def unzip_tree(temp_dir)
    print "unzip_tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*"))
    ls.each do |path|
      print "unzip_tree handling #{path}\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        unzip_tree(path) #recurse
      else
        if File.extname(path) == '.ZIP' || File.extname(path) == '.zip'
          print "Found zipfile #{path}\n"
          #unzip and recur
          destination = File.join(File.dirname(path), File.basename(path).sub(File.extname(path),''))
          print "Calling unzip_file(#{path}, #{destination})"
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
      print "unpdf_tree handling #{path})\n"
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
  def compress_tree(temp_dir)
    print "compress tree(#{temp_dir})\n"
    ls = Dir.glob(File.join(temp_dir, "*"))
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
    ls = Dir.glob(File.join(temp_dir, "*"))
    ls.each do |path|
      print "ingest_tree handling #{path})\n"
      if Dir.exist? path
        print "Found directory #{path}\n"
        ingest_tree(document_upload, path) #recurse
      end
    end    
    # now process this directory if it contains image files
    image_files = Dir.glob(File.join(temp_dir, "*{"+IMAGE_FILE_EXTENSIONS.join(',')+"}"))
    if image_files.length > 0
      print "Found image files in #{temp_dir} -- converting to a work\n"
      convert_to_work(document_upload, temp_dir)
    end
    
  end
  
  def convert_to_work(document_upload, path)
    work = Work.new
    work.owner = document_upload.user
    work.collection = document_upload.collection
    work.title = File.basename(path)
    work.save!
    
    new_dir_name = File.join(Rails.root,
                             "public",
                             "images",
                             "uploaded",
                             work.id.to_s)
    FileUtils.mkdir_p(new_dir_name)
    IMAGE_FILE_EXTENSIONS.each do |ext|
      FileUtils.cp(Dir.glob(File.join(path, "*.#{ext}")), new_dir_name)    
    end    

    # at this point, the new dir should have exactly what we want-- only image files that are adequatley compressed.
    work.description = work.title
    ls = Dir.glob(File.join(new_dir_name, "*"))
    ls.each_with_index do |image_fn,i|
      page = Page.new
      page.title = "#{i}"
      page.base_image = image_fn
      image = Magick::ImageList.new(image_fn)
      page.base_height = image.rows
      page.base_width = image.columns
      image = nil
      GC.start
      work.pages << page      
    end
    work.save!
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


end