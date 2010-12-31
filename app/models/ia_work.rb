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
  
  
end
