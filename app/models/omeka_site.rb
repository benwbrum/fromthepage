class OmekaSite < ActiveRecord::Base
  attr_accessible :api_key, :api_url, :title
  belongs_to :user
  
  validate :site_is_accessible
  before_save :update_title

  def site_is_accessible
    c=OmekaClient::Client.new(self.api_url)
    begin
      c.get_site
    rescue JSON::ParserError
      errors.add(:api_url, "Cannot access site at #{self.api_url} -- check that the URL is a valid URL running version 2.1 or higher of Omeka")     
    end

    unless self.api_key.blank?
      c=OmekaClient::Client.new(self.api_url, self.api_key)
      begin
        c.get_site
      rescue Rest::Wrappers::RestClientExceptionWrapper => e
        errors.add(:api_key, "Cannot access Omeka API with key #{self.api_key}: server returned \"#{e.message}\"")     
      end
    end
  end

  def update_title
    site = client.get_site
    self.title=site.data.title    
  end

  def client
    if self.api_key.blank?
      OmekaClient::Client.new(self.api_url)
    else
      OmekaClient::Client.new(self.api_url, self.api_key)
    end
  end
  
end
