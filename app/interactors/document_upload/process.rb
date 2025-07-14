require 'image_helper'
require 'tempfile'
require 'open-uri'

class DocumentUpload::Process < ApplicationInteractor
  ZIP_EXT = ['.ZIP', '.zip'].freeze
  PDF_EXT = ['.PDF', '.pdf'].freeze

  def initialize(document_upload:)
    @document_upload = document_upload
    @user            = @document_upload.user
    @collection      = @document_upload.collection
    @logs            = String.new

    super
  end

  def perform
    log(<<~MSG)
      found document_upload for:
        user=#{@user.login},
        target collection=#{@collection.title},
        file=#{@document_upload.file}
    MSG

    @document_upload.update!(status: :processing)

    process_batch

    @document_upload.update!(status: :finished)
  rescue StandardError => e
    log("Process Batch: Exception: #{e.message}")
    log(e.backtrace.join("\n"))

    @document_upload.update!(status: :error)
  ensure
    @document_upload.update!(status: :error) unless @document_upload.status_finished?

    if SMTP_ENABLED
      begin
        UserMailer.upload_finished(@document_upload).deliver!
      # :nocov:
      rescue StandardError => e
        log("SMTP Failed: Exception: #{e.message}")
      end
      # :cov:
    end

    File.write(@document_upload.log_file, @logs)
  end

  private

  def process_batch
    # Create temp directory
    temp_dir = File.join(Dir.tmpdir, 'fromthepage_uploads', @document_upload.id.to_s)
    log("creating temp directory #{temp_dir}")
    FileUtils.mkdir_p(temp_dir)

    # Write ActiveStorage attachment to a tempfile
    attachment = @document_upload.attachment # replace with actual attachment name
    filename = attachment.filename.to_s

    tempfile_path = File.join(temp_dir, filename)
    File.open(tempfile_path, 'wb') do |file|
      file.write(attachment.download)
    end

    # Unzip everything
    unzip_tree(temp_dir)

    # Extract any pdfs
    unpdf_tree(temp_dir, @document_upload.ocr)

    # Convert tiffs to jpgs
    untiff_tree(temp_dir)

    # Resize files
    compress_tree(temp_dir)

    # Ingest
    ingest_tree(@document_upload, temp_dir)

    # Clean
    log("Removing #{temp_dir}")
    FileUtils.rm_r(temp_dir)
  end

  def unzip_tree(temp_dir)
    log("unzip_tree(#{temp_dir})")
    ls = Dir.glob(File.join(temp_dir, '*')).sort

    ls.each do |path|
      log("\tunzip_tree considering #{path}")
      if Dir.exist? path
        log("Found directory #{path}")

        # recurse
        unzip_tree(path)
      elsif ZIP_EXT.include?(File.extname(path))
        log("Found zipfile #{path}")
        # unzip
        destination = File.join(File.dirname(path), File.basename(path).sub(File.extname(path), ''))
        log("Calling unzip_file(#{path}, #{destination})")
        ImageHelper.unzip_file(path, destination)

        # recurse
        unzip_tree(destination)
      end
    end

    FileUtils.chmod_R 'u=rwx,go=r', temp_dir
  end

  def unpdf_tree(temp_dir, ocr)
    log("unpdf_tree(#{temp_dir})")

    ls = Dir.glob(File.join(temp_dir, '*')).sort
    ls.each do |path|
      log("\tunpdf_tree considering #{path})")

      if Dir.exist? path
        log("\tunpdf_tree Found directory #{path}")

        # recurse
        unpdf_tree(path, ocr)
      elsif PDF_EXT.include?(File.extname(path))
        log("\t\tunpdf_tree Found pdf #{path}")

        # extract
        destination = ImageHelper.extract_pdf(path, ocr)
        log("\t\tunpdf_tree Extracted to #{destination}")

        # copy any metadata.yml to the destination
        metadata_fn = File.join(File.dirname(path), 'metadata.yml')
        if File.exist? metadata_fn
          log("\t\tunpdf_tree Copy #{metadata_fn} to #{destination}")
          FileUtils.cp(metadata_fn, destination)
        else
          log("\t\tunpdf_tree No metadata file exists at #{metadata_fn}")
        end
      end
    end
  end

  def untiff_tree(temp_dir)
    log("convert tiffs from tree(#{temp_dir})")

    ls = Dir.glob(File.join(temp_dir, '*')).sort
    ls.each do |path|
      log("\tuntiff_tree considering #{path})")
      if Dir.exist? path
        log("Found directory #{path}")

        # recurse
        untiff_tree(path)
      elsif File.extname(path).match TIFF_FILE_EXTENSIONS_PATTERN
        log("Found tiff #{path}")
        # convert tiff to jpg
        destination = ImageHelper.convert_tiff(path)
        log("\t\tuntiff_tree to #{destination}")

        GC.start
      end
    end
  end

  def compress_tree(temp_dir)
    log("compress_tree(#{temp_dir})")

    ls = Dir.glob(File.join(temp_dir, '*')).sort
    ls.each do |path|
      log("compress_tree handling #{path})")
      if Dir.exist? path
        log("Found directory #{path}")

        # recurse
        compress_tree(path)
      elsif File.extname(path).match IMAGE_FILE_EXTENSIONS_PATTERN
        log("Found image #{path}")
        destination = ImageHelper.compress_image(path)
        log("\t\tcompress_tree to #{destination}")
      end
    end
  end

  def ingest_tree(document_upload, temp_dir)
    log("ingest_tree(#{temp_dir})")

    # first process all sub-directories
    clean_dir = temp_dir.gsub('[', '\[').gsub(']', '\]')

    ls = Dir.glob(File.join(clean_dir, '*')).sort
    ls.each do |path|
      log("ingest_tree considering #{path})")
      if Dir.exist? path
        log("Found directory #{path}")

        # recurse
        ingest_tree(document_upload, path)
      end
    end

    # now process this directory if it contains image files
    image_files = Dir.glob(File.join(clean_dir, "*.{#{IMAGE_FILE_EXTENSIONS.join(',')}}")).sort
    if image_files.length > 0
      log("Found #{image_files.length} image files in #{temp_dir} -- converting to a work")
      convert_to_work(document_upload, temp_dir)
      log("Finished converting files in #{temp_dir} to a work")
    end

    log("Finished ingest_tree for #{temp_dir}")
  end

  def convert_to_work(document_upload, path)
    log("convert_to_work creating database record for #{path}")
    log("\tconvert_to_work owner = #{document_upload.user.login}")
    log("\tconvert_to_work collection = #{document_upload.collection.title}")
    log("\tconvert_to_work default title = #{File.basename(path).ljust(3, '.')}")
    log("\tconvert_to_work looking for metadata.yml in #{File.join(File.dirname(path), 'metadata.yml')}")

    begin
      if File.exist? File.join(path, 'metadata.yml')
        yaml = YAML.load_file(File.join(path, 'metadata.yml'))
      elsif File.exist? File.join(path, 'metadata.yaml')
        yaml = YAML.load_file(File.join(path, 'metadata.yaml'))
      else
        log("\tconvert_to_work no metadata.yml file; using default settings")
        yaml = nil
      end
    rescue StandardError => e
      document_upload.update(status: :error)
      log("\n\nYML/YAML Failed: Exception: #{e.message}")

      raise
    end

    log("\tconvert_to_work loaded metadata.yml values \n#{yaml}")

    User.current_user = document_upload.user
    document_sets = []
    if yaml
      yaml.keep_if { |e| INGESTOR_ALLOWLIST.include? e }
      log("\tconvert_to_work allowlisted metadata.yml values \n#{yaml}")
      document_sets = document_sets_from_yaml(yaml, document_upload.collection)
      yaml.delete('document_set')
    end

    work = Work.new(yaml)
    work.owner = document_upload.user
    work.collection = document_upload.collection
    work.title = File.basename(path).ljust(3, '.') unless work.title
    work.uploaded_filename = File.basename(path)

    if document_upload.ocr
      clean_dir = path.gsub('[', '\[').gsub(']', '\]')

      image_basenames = IMAGE_FILE_EXTENSIONS.flat_map do |ext|
        Dir.glob(File.join(clean_dir, "*.#{ext}")).map { |f| File.basename(f, '.*') }
      end.uniq

      has_matching_annotation = image_basenames.any? do |basename|
        txt_path = File.join(clean_dir, "#{basename}.txt")
        xml_path = File.join(clean_dir, "#{basename}.xml")

        (File.exist?(txt_path) && File.read(txt_path).present?) ||
          (File.exist?(xml_path) && File.read(xml_path).present?)
      end

      if has_matching_annotation
        work.ocr_correction = true
      else
        log("\tOCR correction specified but no files found in #{File.join(path, 'page*.txt')} or #{File.join(path, 'page*.xml')}")
      end
    end

    work.save!

    new_dir_name = File.join(Rails.root, 'public', 'images', 'uploaded', work.id.to_s)
    log("\tconvert_to_work creating #{new_dir_name}")

    FileUtils.mkdir_p(new_dir_name)
    IMAGE_FILE_EXTENSIONS.each do |ext|
      # log("\t\tconvert_to_work copying #{File.join(path, "*.#{ext}")} to #{new_dir_name}:")
      clean_dir = path.gsub('[', '\[').gsub(']', '\]')
      FileUtils.cp(Dir.glob(File.join(clean_dir, "*.#{ext}")), new_dir_name)
      Dir.glob(File.join(clean_dir, "*.#{ext}")).sort.each { |fn| log("\t\t\tcp #{fn} to #{new_dir_name}") }
      # log("\t\tconvert_to_work copied #{File.join(path, "*.#{ext}")} to #{new_dir_name}")
    end

    # at this point, the new dir should have exactly what we want-- only image files that are adequately compressed.
    ls = Dir.glob(File.join(new_dir_name, '*')).sort
    numeric_pages, alpha_numeric_pages = ls.partition { |page| File.basename(page).to_i.positive? }
    sorted_numeric_pages = numeric_pages.sort_by { |page| File.basename(page).to_i }
    ls = sorted_numeric_pages.concat(alpha_numeric_pages)

    GC.start
    ls.each_with_index do |image_fn, i|
      page = Page.new
      log("\t\tconvert_to_work created new page")

      page.title = if document_upload.preserve_titles
                     File.basename(image_fn, '.*')
                   else
                     (i + 1).to_s
                   end

      page.base_image = image_fn
      log("\t\tconvert_to_work before Magick call")
      image = Magick::ImageList.new(image_fn)
      GC.start
      log("\t\tconvert_to_work calculating base and height")
      page.base_height = image.rows
      page.base_width = image.columns

      if work.ocr_correction
        ocr_fn = File.join(path, File.basename(image_fn.gsub(IMAGE_FILE_EXTENSIONS_PATTERN, 'txt')))
        xml_fn = File.join(path, File.basename(image_fn.gsub(IMAGE_FILE_EXTENSIONS_PATTERN, 'xml')))
        if File.exist? xml_fn
          log("\t\tconvert_to_work reading raw XML text from #{xml_fn}")
          page.source_text = File.read(xml_fn).gsub(/\[+/, '[').gsub(/\]+/, ']')
          # if there are errors, consider escaping
        elsif File.exist? ocr_fn
          log("\t\tconvert_to_work reading raw OCR text from #{ocr_fn}")
          page.source_text = File.read(ocr_fn).encode(xml: :text).gsub(/\[+/, '[').gsub(/\]+/, ']')
        else
          log("\t\tconvert_to_work raw OCR text missing, setting to ")
        end
      end

      GC.start
      work.pages << page
      log("\t\tconvert_to_work added #{image_fn} to work as page #{page.title}, id=#{page.id}")
    end
    work.save!
    record_deed(work)

    document_sets.each do |ds|
      log("\t\tconvert_to-work adding #{work.title} to document set #{ds.title}")
      ds.works << work
      ds.save!
    end

    log("convert_to_work succeeded for #{work.title}")
  end

  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = DeedType::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end

  def document_sets_from_yaml(yaml, collection)
    document_sets = []
    if yaml['document_set'].is_a?(Array)
      yaml['document_set'].each do |set_title|
        ds = collection.document_sets.where(title: set_title).first
        unless ds
          log("\t\t\tdocument_sets_from_yaml creating document set #{set_title}")
          ds = DocumentSet.new
          ds.title = set_title
          ds.collection = collection
          # inherit public setting of parent collection
          ds.visibility = collection.restricted ? :private : :public
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

  def log(text)
    @logs += "#{text}\n"
  end
end
