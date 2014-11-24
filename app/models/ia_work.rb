class IaWork < ActiveRecord::Base
  require 'open-uri'

  belongs_to :user
  belongs_to :work
  has_many :ia_leaves

  def self.refresh_server(book_id)
      # first get the call the location API and parse that document
    api_url = 'http://www.archive.org/services/find_file.php?file='+book_id
    logger.debug(api_url)
    loc_doc = Nokogiri::HTML(open(api_url))
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']
    logger.debug "DEBUG Server=#{server}"
    logger.debug "DEBUG Dir=#{dir}"
    return {:server => server, :ia_path => dir}
  end

  def zip_file
    self[:zip_file] || "#{self[:book_id]}_#{self[:image_format]}.#{self[:archive_format]}"
  end

  def book_path
    # this is either the straightforward ia_path, or something different based
    # on the sloppy filename feature

    # short-circuit for backwards compatibility
    unless self[:scandata_file]
      return self[:ia_path]
    end

    scandata_stub = self[:scandata_file].sub(/_scandata.xml/, '')
    if scandata_stub == self.book_id
      return self[:ia_path]
    else
      return "#{self[:ia_path]}/#{scandata_stub}"
    end
  end


  def sub_prefix
    unless self[:scandata_file]
      return self[:book_id]
    end

    scandata_stub = self[:scandata_file].sub(/_scandata.xml/, '')
    if scandata_stub == self.book_id
      return self[:book_id]
    else
      return "#{scandata_stub}"
    end

  end



  # IA importer code refactored from ia_controller.rb
  def convert_to_work
    work = Work.new
    work.owner = self.user
    work.title = self.title
    work.description = self.description
    work.physical_description = self.notes
    work.author = self.creator
    work.description += "<br/>Sponsored by: "+ self.sponsor
    work.description += "<br/>Contributed by: "+ self.contributor
    work.save!

    self.ia_leaves.each do |leaf|
      page = Page.new
      page.base_image = nil
      page.base_height = leaf.page_h
      page.base_width = leaf.page_w
      page.title = leaf.page_number
      page.source_text = leaf.ocr_text
      work.pages << page #necessary to make acts_as_list work here
      work.save!
      leaf.page_id = page.id
      leaf.save!
    end
    work.save!
    self.work = work
    self.save!

    work
  end

  def ingest_work(id)
    
    loc_doc = fetch_loc_doc(id)
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']

    self.server = server
    self.ia_path = dir

    self.book_id = loc_doc.search('identifier').text
    self[:title] = loc_doc.search('title').text             #work title
    self[:creator] = loc_doc.search('creator').text          #work author
    self[:collection] = loc_doc.search('collection').text   #?
    self[:description] = loc_doc.search('description').text #description
    self[:subject] = loc_doc.search('subject').text         #description
    self[:notes] = loc_doc.search('notes').text             #physical description
    self[:contributor] = loc_doc.search('contributor').text #description
    self[:sponsor] = loc_doc.search('sponsor').text         #description
    self[:image_count] = loc_doc.search('imagecount').text

    image_format, archive_format = formats_from_loc(loc_doc)
    logger.debug("image_format, archive_format = #{image_format}, #{archive_format}")
    self[:image_format] = image_format
    self[:archive_format] = archive_format
    scandata_file, djvu_file, zip_file = files_from_loc(loc_doc)
    self[:scandata_file] = scandata_file
    self[:djvu_file] = djvu_file
    self[:zip_file] = zip_file

    self.save!
    # now fetch the scandata.xml file and parse it
    scandata_url = "http://#{server}#{dir}/#{scandata_file}" # will not work on new format: we cannot assume filenames are re-named with their content

    sd_doc = Nokogiri::XML(open(scandata_url))

    @pages = sd_doc.search('page')
    @pages.each do |page|
      leaf = IaLeaf.new
      leaf.leaf_number = page['leafNum']
      if nil == leaf.leaf_number
        leaf.leaf_number = page['leafnum'] #bpoc installation downcases this for some reason
      end
      leaf.page_number = page.search('pagenumber').text
      leaf.page_type = page.search('pagetype').text
      leaf.page_w = page.search('w').text
      leaf.page_h = page.search('h').text
      self.ia_leaves << leaf

      if leaf.page_type == 'Title'
        self.title_leaf = leaf.leaf_number
      end
    end
    self.save!

    text_from_ocr
    self.save!

    self
  end
  
  def text_from_ocr
    djvu_doc = ocr_doc
    
    leaf_objects = djvu_doc.search('OBJECT')
    leaf_objects.each do |e|
      leaf_number = leaf_number_from_object(e)
      ia_leaf = self.ia_leaves.find_by_leaf_number(leaf_number)
      
      ia_leaf.ocr_text = ""

      e.search('PARAGRAPH').each do |para|
        para.search('LINE').each do |line|
          ia_leaf.ocr_text << ocr_line_to_text(line)
          ia_leaf.ocr_text << "\n"
        end
        ia_leaf.ocr_text << "\n"
      end
      ia_leaf.save!
    end
  end
 
  def title_from_ocr(location)
    djvu_doc = ocr_doc
    
    leaf_objects = djvu_doc.search('OBJECT')
    leaf_objects.each do |e|

      page_id = e.search('PARAM[@name="PAGE"]').first['value']
      page_id[/\w*_0*/]=""
      page_id[/\.djvu/]=''
      logger.debug(page_id)
      # there may well be an off-by-one error in the source.  I'm seeing page_id 7
      # correspond with leaf_id 6
      leaf_number = leaf_number_from_object(e)

      if location == :top
        line = e.search('LINE').first
      else
        line = e.search('LINE').last
      end
              
      if(line)
        ia_leaf = self.ia_leaves.find_by_leaf_number(leaf_number)
        ia_leaf.page_number = ocr_line_to_text(line).titleize
        ia_leaf.save!
      end
    end

  end
  
  
private
  def leaf_number_from_object(object_element)

      page_id = object_element.search('PARAM[@name="PAGE"]').first['value']
      page_id[/\w*_0*/]=""
      page_id[/\.djvu/]=''
      logger.debug(page_id)
      # there may well be an off-by-one error in the source.  I'm seeing page_id 7
      # correspond with leaf_id 6
      page_id.to_i
    
  end
  
  def ocr_line_to_text(line)
    words = []

    line.search('WORD').each { |e| words << e.inner_text }
    title = words.join(" ")

    title    
  end

  def ocr_doc
    loc_doc = fetch_loc_doc(self.book_id)
    scandata_file, djvu_file = files_from_loc(loc_doc)

    djvu_url =  "http://#{self.server}#{self.ia_path}/#{djvu_file}"
    logger.debug(djvu_url)
    djvu_doc = Nokogiri::XML(open(djvu_url))

    djvu_doc
  end 


  ARCHIVE_FORMATS = ['zip', 'tar']
  IMAGE_FORMATS = ['jp2', 'jpg']

  def formats_from_loc(loc_doc)
    files = loc_doc.search 'file'
    locations = files.map { |f| f['location'] }
    # handle new upload format
    if locations.uniq == [nil]
      return ['jp2', 'zip']
    end
    # handle old upload format
    ARCHIVE_FORMATS.each do |aft|
      IMAGE_FORMATS.each do |ift|
        suffix = "#{ift}.#{aft}"
        if locations.count { |l| l.end_with? suffix} > 0
          return [ift, aft]
        end
      end
    end
  end

  def fetch_loc_doc(id)
    # first get the call the location API and parse that document
    api_url = 'http://www.archive.org/services/find_file.php?file='+id
    logger.debug(api_url)
    loc_doc = Nokogiri::XML(open(api_url))
    return loc_doc
  end

  def files_from_loc(loc_doc)
    formats = loc_doc.search('file').search('format')
    scandata = formats.select{|e| e.inner_text=='Scandata'}.first.parent['name']
    djvu = formats.select{|e| e.inner_text=='Djvu XML'}.first.parent['name']
    zips = formats.select{|e| e.inner_text=='Single Page Processed JP2 ZIP'}
    if zips.size < 1
      zips = formats.select{|e| e.inner_text=='Single Page Processed JP2 Tar'}
    end
    zip = zips.first.parent['name']

    return [scandata, djvu, zip]
  end


end
