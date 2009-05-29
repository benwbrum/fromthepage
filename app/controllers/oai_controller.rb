class OaiController < ApplicationController
  require 'oai'

  def identify_repository
    client = OAI::Client.new params[:repository_url]
    @identify_response = client.identify       
  end
  
  def metadata_format_list
    client = OAI::Client.new params[:repository_url]
    @list_metadata_formats_response = client.list_metadata_formats    
  end

  def set_list
    client = OAI::Client.new params[:repository_url]
    @list_sets_response = client.list_sets
  end

  def record_list
    client = OAI::Client.new params[:repository_url]
    set_spec = params[:set_spec]
    @list_records_response = 
      client.list_records({:metadata_prefix => 'oai_dc',
                           :set => set_spec})
  end

  def repository_list
    @repository_urls = 
      ['http://tides.sfasu.edu:2006/cgi-bin/oai.exe',
       'http://digital.lib.uiowa.edu/cgi-bin/oai.exe']
  end

end
