class IaController < ApplicationController
  require 'hpricot'
  require 'open-uri'
  before_filter :load_ia_work_from_params

  def load_ia_work_from_params
    unless params[:ia_work_id].blank?
      @ia_work = IaWork.find(params[:ia_work_id])   
    end
  end

  def convert
    work = Work.new
    work.owner = current_user
    work.title = @ia_work.title
    work.description = @ia_work.description
    work.physical_description = @ia_work.notes
    work.author = @ia_work.creator
    work.description += "<br/>Sponsored by: "+ @ia_work.sponsor
    work.description += "<br/>Contributed by: "+ @ia_work.contributor
    work.save!

    @ia_work.ia_leaves.each do |leaf|
      page = Page.new
      page.base_image = nil
      page.base_height = leaf.page_h
      page.base_width = leaf.page_w
      page.title = leaf.page_number
      work.pages << page #necessary to make acts_as_list work here
      work.save!
      leaf.page_id = page.id
      leaf.save!
    end
    work.save!
    @ia_work.work = work
    @ia_work.save!
    flash[:notice] = "#{@ia_work.title} has been converted into a FromThePage work."
    
    redirect_to :controller => 'work', :action => 'edit', :work_id => work.id
    
    #
#    @image_set.titled_images.each do |titled_image|
#      page = Page.new
#      page.base_image = titled_image.original_file
#      if File.exists?(page.base_image)
#        image = Magick::ImageList.new(page.base_image)
#        page.base_height = image.rows
#        page.base_width = image.columns
#        image = nil
#        GC.start
#      end   
#      # width
#      # height
#      page.shrink_factor = @image_set.original_to_base_halvings
#      page.title = titled_image.title
#      work.pages << page
#    end
#    work.save!
#    redirect_to :controller => 'work', :action => 'edit', :work_id => work.id
  end



  def purge_type_delete
    leaves_to_delete = @ia_work.ia_leaves.find_all_by_page_type('Delete')
    leaves_to_delete.each do |l|
      IaLeaf.destroy(l.id)
    end
    flash[:notice] = "Delete leaves have been purged"
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end

  def title_from_ocr
    
    loc_doc = fetch_loc_doc(@ia_work.book_id)
    scandata_file, djvu_file = files_from_loc(loc_doc)
    
    djvu_url =  "http://#{@ia_work.server}#{@ia_work.ia_path}/#{djvu_file}"
    logger.debug(djvu_url)
    djvu_doc = Hpricot(open(djvu_url))
    leaf_objects = djvu_doc.search('object')
    leaf_objects.each do |e|

      page_id = e.search('/param[@name="PAGE"]').first['value']
      page_id[/\w*_0*/]=""
      page_id[/\.djvu/]=''
      logger.debug(page_id)
      # there may well be an off-by-one error in the source.  I'm seeing page_id 7
      # correspond with leaf_id 6
      leaf_number = page_id.to_i

      line = e.search('line').first
      if(line) 
        words = []
        
        line.search('word').each { |e| words << e.inner_text.capitalize }
        title = words.join(" ")
        logger.debug(title)
        
        ia_leaf = @ia_work.ia_leaves.find_by_leaf_number(leaf_number)
        ia_leaf.page_number = title
        ia_leaf.save!

      end
    end
    flash[:notice] = "Pages have been renamed."
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end
    
  def confirm_import
    @detail_url = params[:detail_url]
    #id = detail_url.split('/').last

    @matches = IaWork.find_all_by_detail_url(@detail_url)
    if @matches.size() == 0
      # nothing to do here
      redirect_to :action => 'import_work', :detail_url => @detail_url    
      return 
    end
  end
    
  def import_work 
    # bail if the user bailed
    if params[:commit] == 'Cancel'
      redirect_to :controller => 'dashboard', :action => 'main_dashboard'
      return
    end
    detail_url = params[:detail_url]
    id = detail_url.split('/').last

    loc_doc = fetch_loc_doc(id)
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']
    
    # pull relevant info about the work from here
    @ia_work = IaWork.new
    @ia_work.server = server
    @ia_work.ia_path = dir
    @ia_work.user_id = @current_user.id
    @ia_work.detail_url = detail_url
    
    @ia_work.book_id = loc_doc.search('identifier').text
    @ia_work[:title] = loc_doc.search('title').text             #work title
    @ia_work[:creator] = loc_doc.search('creator').text          #work author
    @ia_work[:collection] = loc_doc.search('collection').text   #?
    @ia_work[:description] = loc_doc.search('description').text #description
    @ia_work[:subject] = loc_doc.search('subject').text         #description
    @ia_work[:notes] = loc_doc.search('notes').text             #physical description
    @ia_work[:contributor] = loc_doc.search('contributor').text #description
    @ia_work[:sponsor] = loc_doc.search('sponsor').text         #description
    @ia_work[:image_count] = loc_doc.search('imagecount').text   

    image_format, archive_format = formats_from_loc(loc_doc)
    logger.debug("image_format, archive_format = #{image_format}, #{archive_format}")
    @ia_work[:image_format] = image_format
    @ia_work[:archive_format] = archive_format

    scandata_file, djvu_file, zip_file = files_from_loc(loc_doc)
    @ia_work[:scandata_file] = scandata_file
    @ia_work[:djvu_file] = djvu_file
    @ia_work[:zip_file] = zip_file
    
    @ia_work.save!
    # now fetch the scandata.xml file and parse it
    scandata_url = "http://#{server}#{dir}/#{scandata_file}" # will not work on new format: we cannot assume filenames are re-named with their content
    
    sd_doc = Hpricot(open(scandata_url))
    
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
      @ia_work.ia_leaves << leaf
      
      if leaf.page_type == 'Title'
        @ia_work.title_leaf = leaf.leaf_number
      end
    end
    @ia_work.save!
    flash[:notice] = "#{@ia_work.title} has been imported into your staging area."
   
    redirect_to :action => 'manage', :ia_work_id => @ia_work.id
  end
  
private
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
    loc_doc = Hpricot(open(api_url))
    return loc_doc
  end
  
  def files_from_loc(loc_doc)
    formats = loc_doc.search('file').search('format')
    scandata = formats.select{|e| e.inner_text=='Scandata'}.first.parent['name']
    djvu = formats.select{|e| e.inner_text=='Djvu XML'}.first.parent['name']
    zip = formats.select{|e| e.inner_text=='Single Page Processed JP2 ZIP'}.first.parent['name']
    return [scandata, djvu, zip]    
  end
  
end
