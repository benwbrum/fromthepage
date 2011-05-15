class IaWork < ActiveRecord::Base
  require 'hpricot'
  require 'open-uri'

  belongs_to :user
  belongs_to :work
  has_many :ia_leaves

  def self.refresh_server(book_id)
      # first get the call the location API and parse that document
    api_url = 'http://www.archive.org/services/find_file.php?file='+book_id
    logger.debug(api_url)
    loc_doc = Hpricot(open(api_url))
    location = loc_doc.search('results').first
    server = location['server']
    dir = location['dir']
    logger.debug "DEBUG Server=#{server}"
    logger.debug "DEBUG Dir=#{dir}"
    return {:server => server, :ia_path => dir}
  end
  
  def zip_file
    self[:zip_file] || "<%=self[:book_id]%>_<%=self[:image_format]%>.<%=self[:archive_format]%>"
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
  
end
