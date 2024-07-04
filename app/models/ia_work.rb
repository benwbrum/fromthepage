# == Schema Information
#
# Table name: ia_works
#
#  id             :integer          not null, primary key
#  archive_format :string(255)      default("zip")
#  collection     :string(255)
#  contributor    :string(255)
#  creator        :string(255)
#  description    :string(1024)
#  detail_url     :string(255)
#  djvu_file      :string(255)
#  ia_path        :string(255)
#  image_count    :string(255)
#  image_format   :string(255)      default("jp2")
#  notes          :string(255)
#  scandata_file  :string(255)
#  server         :string(255)
#  sponsor        :string(255)
#  subject        :string(255)
#  title          :string(255)
#  title_leaf     :integer
#  use_ocr        :boolean          default(FALSE)
#  zip_file       :string(255)
#  created_at     :datetime
#  updated_at     :datetime
#  book_id        :string(255)
#  user_id        :integer
#  work_id        :integer
#
class IaWork < ApplicationRecord

  require 'open-uri'

  belongs_to :user, optional: true
  belongs_to :work, optional: true
  has_many :ia_leaves, class_name: 'IaLeaf'

  before_create :truncate_title

  def truncate_title
    self.title = title.truncate(255, omission: '...')
  end

  def display_page
    # blank status of raw ocr before displaying -- if the user hits save, status will become default
    #  if @page.status == Page::STATUS_RAW_OCR
    #    @page.status = nil;
    #  end
  end

  def self.refresh_server(book_id)
    # first get the call the location API and parse that document
    api_url = "http://www.archive.org/services/find_file.php?file=#{book_id}"
    logger.debug(api_url)
    loc_doc = Nokogiri::HTML(URI.open(api_url))
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']
    logger.debug "DEBUG Server=#{server}"
    logger.debug "DEBUG Dir=#{dir}"
    { server:, ia_path: dir }
  end

  def zip_file
    self[:zip_file] || "#{self[:book_id]}_#{self[:image_format]}.#{self[:archive_format]}"
  end

  def book_path
    # this is either the straightforward ia_path, or something different based
    # on the sloppy filename feature

    # short-circuit for backwards compatibility
    return self[:ia_path] unless self[:scandata_file]

    scandata_stub = self[:scandata_file].sub(/_scandata.xml/, '')
    return self[:ia_path] if scandata_stub == book_id

    "#{self[:ia_path]}/#{scandata_stub}"
  end

  def sub_prefix
    return self[:book_id] unless self[:scandata_file]

    scandata_stub = self[:scandata_file].sub(/_scandata.xml/, '')

    return self[:book_id] if scandata_stub == book_id

    scandata_stub.to_s
  end

  # IA importer code refactored from ia_controller.rb
  def convert_to_work
    work = Work.new
    work.owner = user
    work.title = title
    work.description = description
    work.physical_description = notes
    work.author = creator
    work.ocr_correction = true if use_ocr
    work.slug = book_id
    work.save!

    ia_leaves.each do |leaf|
      page = Page.new
      page.base_image = nil
      page.base_height = leaf.page_h
      page.base_width = leaf.page_w
      page.title = leaf.page_number
      page.source_text = leaf.ocr_text if use_ocr
      work.pages << page # necessary to make acts_as_list work here
      work.save!

      leaf.page_id = page.id
      leaf.save!
    end
    work.save!
    record_deed(work)

    self.work = work
    save!
    work
  end

  def ingest_work(id)
    # find the length of the description column
    limit = IaWork.columns_hash['description'].limit
    loc_doc = fetch_loc_doc(id)
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']

    self.server = server
    self.ia_path = dir
    self.book_id = loc_doc.search('identifier').text
    self[:title] = loc_doc.search('title').text # work title
    self[:creator] = loc_doc.search('creator').map(&:text).join('; ') # work author
    self[:collection] = loc_doc.search('collection').text # ?
    # description is truncated so it isn't too long for the description column
    if loc_doc.search('abstract').blank?
      self[:description] = loc_doc.search('description').text.truncate(limit) # description
    else
      self[:description] = loc_doc.search('abstract').text.truncate(limit) # description
    end
    self[:notes] = loc_doc.search('notes').text # physical description
    self[:image_count] = loc_doc.search('imagecount').text

    image_format, archive_format = formats_from_loc(loc_doc)
    logger.debug("image_format, archive_format = #{image_format}, #{archive_format}")
    self[:image_format] = image_format
    self[:archive_format] = archive_format
    scandata_file, djvu_file, zip_file = files_from_loc(loc_doc)
    self[:scandata_file] = scandata_file
    self[:djvu_file] = djvu_file
    self[:zip_file] = zip_file

    save!
    # now fetch the scandata.xml file and parse it
    scandata_url = "http://#{server}#{dir}/#{URI.encode(scandata_file)}" # will not work on new format: we cannot assume filenames are re-named with their content

    sd_doc = open_doc(scandata_url)

    @pages = sd_doc.search('page')
    @pages.each do |page|
      leaf = IaLeaf.new
      leaf.leaf_number = page.xpath('@leafNum|@leafnum').text
      leaf.page_number = page.xpath('pageNumber|pagenumber').text
      altpageelement = page.children.xpath('altPageNumber')
      leaf.page_number = "#{altpageelement.attr('prefix').value} [#{altpageelement.children.text}]" if altpageelement.present?
      leaf.page_type = page.xpath('pageType|pagetype').text
      leaf.page_w = page.xpath('(cropBox|cropbox)/w').text
      leaf.page_h = page.xpath('(cropBox|cropbox)/h').text
      ia_leaves << leaf

      self.title_leaf = leaf.leaf_number if leaf.page_type == 'Title'
    end
    save!

    text_from_ocr
    save!

    self
  end

  def text_from_ocr
    djvu_doc = ocr_doc
    leaf_objects = djvu_doc.search('OBJECT')
    leaf_objects.each do |e|
      leaf_number = leaf_number_from_object(e)
      ia_leaf = ia_leaves.find_by(leaf_number:)

      ia_leaf.ocr_text = ''

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
      page_id[/\w*_0*/] = ''
      page_id[/\.djvu/] = ''
      logger.debug(page_id)
      # there may well be an off-by-one error in the source.  I'm seeing page_id 7
      # correspond with leaf_id 6
      leaf_number = leaf_number_from_object(e)

      if location == :top
        line = e.search('LINE').first
      else
        line = e.search('LINE').last
      end

      next unless line

      ia_leaf = ia_leaves.find_by(leaf_number:)
      ia_leaf.page_number = ocr_line_to_text(line).titleize
      ia_leaf.save!
    end
  end

  private

  def open_doc(url)
    Nokogiri::XML(URI.open(url).read.force_encoding('utf-8'), nil, 'utf-8')
  end

  def leaf_number_from_object(object_element)
    page_id = object_element.search('PARAM[@name="PAGE"]').first['value']
    page_id[/\S*_0*/] = ''
    page_id[/\.djvu/] = ''
    logger.debug(page_id)
    # there may well be an off-by-one error in the source.  I'm seeing page_id 7
    # correspond with leaf_id 6
    page_id.to_i
  end

  def ocr_line_to_text(line)
    words = line.search('WORD').map(&:inner_text)
    title = words.join(' ')
    # clean any angle braces -- this source won't be HTML
    title.gsub!('<', '&lt;')
    title.gsub!('>', '&gt;')
    title.gsub!(/\[\[+/, '[')

    title
  end

  def ocr_doc
    loc_doc = fetch_loc_doc(book_id)
    _, djvu_file = files_from_loc(loc_doc)

    djvu_url = "http://#{server}#{ia_path}/#{URI.encode(djvu_file)}"
    logger.debug(djvu_url)
    open_doc(djvu_url)
  end

  ARCHIVE_FORMATS = ['zip', 'tar']
  IMAGE_FORMATS = ['jp2', 'jpg']

  def formats_from_loc(loc_doc)
    files = loc_doc.search 'file'
    locations = files.pluck('location')
    # handle new upload format
    return ['jp2', 'zip'] if locations.uniq == [nil]

    # handle old upload format
    ARCHIVE_FORMATS.each do |aft|
      IMAGE_FORMATS.each do |ift|
        suffix = "#{ift}.#{aft}"
        return [ift, aft] if locations.count { |l| l.end_with? suffix } > 0
      end
    end
  end

  def fetch_loc_doc(id)
    # first get the call the location API and parse that document
    api_url = "http://www.archive.org/services/find_file.php?file=#{id}"
    logger.debug(api_url)
    open_doc(api_url)
  end

  def files_from_loc(loc_doc)
    formats = loc_doc.search('file').search('format')

    scandata = formats.select { |e| e.inner_text == 'Scandata' }.first.parent['name']
    djvu = formats.select { |e| e.inner_text == 'Djvu XML' }.first.parent['name']
    zips = formats.select { |e| e.inner_text == 'Single Page Processed JP2 ZIP' }
    zips = formats.select { |e| e.inner_text == 'Single Page Processed JP2 Tar' } if zips.size < 1
    zips = formats.select { |e| e.inner_text == 'Single Page Processed JPEG Tar' } if zips.size < 1

    zip = zips.first.parent['name']

    [scandata, djvu, zip]
  end

  protected

  def record_deed(work)
    deed = Deed.new
    deed.work = work
    deed.deed_type = DeedType::WORK_ADDED
    deed.collection = work.collection
    deed.user = work.owner
    deed.save!
  end

end
