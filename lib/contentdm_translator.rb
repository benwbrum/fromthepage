module ContentdmTranslator
  def self.update_work_from_cdm(work, ocr_correction=false)
    # is there any sort of handle we need to keep at the work level?

    # find the work manifest -- bail out if there is none
    return unless work.sc_manifest
    # make sure the manifest is cdm
    return unless iiif_manifest_is_cdm? work.sc_manifest.at_id
    # for each page
    work.pages.each do |page|
      update_page_from_cdm(page, ocr_correction)
    end
    work.ocr_correction=ocr_correction
    work.save!
  end

  def self.update_page_from_cdm(page, ocr_correction)
    # fetch the cdm metadata
    info = fetch_cdm_info(page)
    # prune the boilerplate
    metadata = metadata_from_cdm_info(info)
    # store the metadata on the page
    page.metadata=metadata

    if ocr_correction
      ocr = ocr_from_cdm_info(info)
      page.source_text = ocr.encode(:xml => :text) if ocr
    end

    page.save!
  end

  def self.fetch_cdm_info(page)
    cdm_url = page_at_id_to_cdm_item_info(page.sc_canvas.sc_canvas_id)
    cdm_response = open(cdm_url).read
    JSON.parse(cdm_response)
  end

  ITEM_INFO_BLACKLIST = [
    "descri",
    "date",
    "creato",
    "subjec",
    "relate",
    "type",
    "publis",
    "langua",
    "rights",
    "transc",
    "contac",
    "fullrs",
    "find",
    "dmaccess",
    "dmimage",
    "dmcreated",
    "dmmodified",
    "dmoclcno",
    "restrictionCode",
    "cdmfilesize",
    "cdmfilesizeformatted",
    "cdmprintpdf",
    "cdmhasocr",
    "cdmisnewspaper"]

  def self.metadata_from_cdm_info(info)
    # only return useful and unique things
    info.except(*ITEM_INFO_BLACKLIST)
  end

  def self.ocr_from_cdm_info(info)
    transcript = info['transc']
    if transcript.kind_of? String
    transcript
    else
      nil
    end
  end

  def self.page_at_id_to_cdm_item_info(at_id)
    cdm = at_id.sub(/cdm/, 'server')
    cdm.sub!(/digital\/iiif/, 'dmwebservices/index.php?q=dmGetItemInfo')
    cdm.sub!(/\/canvas\/c\d*/, '/json')

    cdm
  end

  def self.iiif_manifest_is_cdm?(at_id)
    at_id.match(/contentdm.oclc.org/)
  end

  def self.cdm_item_info_from_iiif(at_id)
    cdm = at_id.sub(/cdm/, 'server')
    cdm.sub!(/digital\/iiif-info/, 'dmwebservices/index.php?q=dmGetItemInfo')
  end

  def self.collection_is_cdm?(collection)
    imported_work = collection.works.joins(:sc_manifest).last
    imported_work && iiif_manifest_is_cdm?(imported_work.sc_manifest.at_id)
  end

  def self.fst_field_for_collection(collection, license_key, contentdm_user_name, contentdm_password)
    error = nil
    fts_field = nil
    at_id = sample_manifest(collection).at_id

    soap_client = Savon.client(:wsdl => 'https://worldcat.org/webservices/contentdm/catcher?wsdl')
    message = {
      :cdmurl => "http://#{cdm_server(at_id)}:8888",
      :username => contentdm_user_name,
      :password => contentdm_password,
      :license => license_key,
      :collection => cdm_collection(at_id)}
    resp = soap_client.call(:get_conten_tdm_collection_config, :message => message )

    doc = Nokogiri::XML resp.hash[:envelope][:body][:get_conten_tdm_collection_config_response][:return]

    if doc.children.count == 0
      # error response
      error = Nokogiri::HTML(resp.hash[:envelope][:body][:get_conten_tdm_collection_config_response][:return]).text
    elsif doc.search("//field/type[text()='FTS']").count == 0
      # no FTS
      error = "No full-text search (FTS) fields were configured on collection #{cdm_collection(at_id)}!"
    else
    # good response
      fts_field = doc.search("//field/type[text()='FTS']").first.parent.search('name').text
    end

    return error, fts_field
  end

  def self.export_work_to_cdm(work, username, password, license)
    soap_client = Savon.client(:wsdl => 'https://worldcat.org/webservices/contentdm/catcher?wsdl')
    work.pages.each do |page|
      at_id = page.sc_canvas.sc_canvas_id
      puts "\nUpdating #{cdm_collection(at_id)}\trecord #{cdm_record(at_id)}\tfrom #{page.title}\t#{page.id}\t#{work.title}.  CONTENTdm response:"
      metadata_wrapper = {
        'metadataList' => {
          'metadata' => [
            { :field => 'dmrecord', :value => cdm_record(at_id)},
            { :field => "transc", :value => page.source_text}
          ]
        }
      }

      message = {
        :cdmurl => "http://#{cdm_server(at_id)}:8888",
        :username => username,
        :password => password,
        :license => license,
        :collection => cdm_collection(at_id),
        :metadata => metadata_wrapper,
        :action => 'edit'
      }
      resp = soap_client.call(:process_conten_tdm, :message => message )
      puts resp.to_hash[:process_conten_tdm_response][:return]

    end
  end

  def self.log_file(collection)
    File.join(Rails.root, 'public', 'imports', "cdm_sync_#{collection.id}.log")
  end

  def self.log_contents(collection)
    STDOUT.flush
    File.read(log_file(collection))
  end

  private

  def self.cdm_server(at_id)
    at_id.sub(/https:\/\/cdm/,'server').sub(/\/.*/,'')
  end

  def self.cdm_collection(at_id)
    at_id.sub(/.*digital\/iiif(-info)?\//,'').sub(/\/.*/, '')
  end

  def self.cdm_record(at_id)
    at_id.sub(/\/canvas\/.*/,'').sub(/^.*\//, '')
  end

  def self.cdm_url_to_iiif(url)
    matches = url.match(/https?:\/\/(cdm\d+).*collection\/(\w+)\/id\/(\d+)/)
    if matches
      server = matches[1]
      collection = matches[2]
      record = matches[3]
      
      "https://#{server}.contentdm.oclc.org/digital/iiif-info/#{collection}/#{record}/manifest.json"
    else
      raise "ContentDM URLs must be of the form http://cdmNNNNN.contentdm.oclc.org/..."
    end
  end

  def self.sample_manifest(collection)
    imported_work = collection.works.joins(:sc_manifest).last

    imported_work && imported_work.sc_manifest
  end
end