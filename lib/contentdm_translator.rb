module ContentdmTranslator

  def self.update_work_from_cdm(work, ocr_correction=false)
    # find the work manifest -- bail out if there is none
    return unless work.sc_manifest
    # make sure the manifest is cdm
    return unless iiif_manifest_is_cdm? work.sc_manifest.at_id

    if ocr_correction
      # get the fts field for this collection
      fts_error, fts_field = fts_field_for_collection(work.collection)
      if fts_error
        puts "Error retrieving Full-Text Search field: #{error}\n"
      end
    end
    # for each page
    work.pages.each do |page|
      update_page_from_cdm(page, ocr_correction, fts_field)
    end
    work.ocr_correction=ocr_correction
    work.save!
  end

  def self.update_page_from_cdm(page, ocr_correction, fts_field)
    # fetch the cdm metadata
    info = fetch_cdm_info(page)
    # prune the boilerplate
    metadata = metadata_from_cdm_info(info)
    # store the metadata on the page
    page_columns = { metadata: metadata }

    if ocr_correction
      ocr = ocr_from_cdm_info(info, fts_field)
      page_columns[:source_text] = ocr.encode(:xml => :text) if ocr
    end

    page.update_columns(page_columns)
  end

  def self.fetch_cdm_info(page)
    cdm_url = page_at_id_to_cdm_item_info(page.sc_canvas.sc_canvas_id)
    cdm_response = URI.open(cdm_url).read
    JSON.parse(cdm_response)
  end

  def self.fetch_cdm_field_config(collection)
    cdm_url = collection_to_cdm_field_config(collection)
    cdm_response = URI.open(cdm_url).read
    JSON.parse(cdm_response)
  end

  ITEM_INFO_DENYLIST = [
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
    info.except(*ITEM_INFO_DENYLIST)
  end

  def self.ocr_from_cdm_info(info, fts_field)
    transcript = info[fts_field]
    if transcript.kind_of? String
      transcript
    else
      nil
    end
  end

  def self.page_at_id_to_cdm_item_info(at_id)
    cdm = at_id.sub(/cdm/, 'server')
    cdm.sub!(/(digital\/)?iiif/, 'dmwebservices/index.php?q=dmGetItemInfo')
    cdm.sub!(/\/canvas\/c\d*/, '/json')
    cdm.sub!(/:(\d+)/, '/\1') # handle coollection:id format instead of old collection/id

    cdm
  end

  def self.collection_to_cdm_field_config(collection)
    at_id = collection.pages.joins(:sc_canvas).reorder('pages.created_on').last.sc_canvas.sc_canvas_id
    cdm = at_id.sub(/cdm/, 'server')
    cdm.sub!(/(digital\/)?iiif/, 'dmwebservices/index.php?q=dmGetCollectionFieldInfo')
    cdm.sub!(/(:\d+)?\/canvas\/c\d*/, '/json')

    cdm
  end



  def self.iiif_manifest_is_cdm?(at_id)
    at_id.match(/contentdm.oclc.org/) || at_id.match(/iiif\/info\/\w+\/\d+\/manifest.json/)
  end

  def self.cdm_item_info_from_iiif(at_id)
    cdm = at_id.sub(/cdm/, 'server')
    cdm.sub!(/digital\/iiif-info/, 'dmwebservices/index.php?q=dmGetItemInfo')
  end

  def self.collection_is_cdm?(collection)
    imported_work = collection.works.joins(:sc_manifest).last
    imported_work && iiif_manifest_is_cdm?(imported_work.sc_manifest.at_id)
  end

  def self.fts_field_for_collection(collection)
    field_config = fetch_cdm_field_config(collection)
    fts_field = field_config.detect { |element| element["type"] == "FTS"}
    if fts_field
      fts = fts_field['nick']
      error = nil
    else
      fts = nil
      error = "No full-text search (FTS) fields were configured on CONTENTdm collection!"
    end
    return error, fts
  end


  def self.export_work_to_cdm(work, username, password, license)
    error, fieldname = fts_field_for_collection(work.collection)
    if error
      puts "Error retrieving Full-Text Search field: #{error}\n"
      exit
    end

    soap_client = Savon.client(:log=>true, filters: [:password], :wsdl => 'https://worldcat.org/webservices/contentdm/catcher?wsdl')
    work.pages.each do |page|
      canvas_at_id = page.sc_canvas.sc_canvas_id
      manifest_at_id = work.sc_manifest.at_id
      puts "\nUpdating #{cdm_collection(manifest_at_id)}\trecord #{cdm_record(canvas_at_id)}\tfrom #{page.title}\t#{page.id}\t#{work.title}.  CONTENTdm response:"
      metadata_wrapper = {
        'metadataList' => {
          'metadata' => [
            { :field => 'dmrecord', :value => cdm_record(canvas_at_id)},
            { :field => fieldname, :value => page.verbatim_transcription_plaintext}
          ]
        }
      }

      message = {
        :cdmurl => "http://#{cdm_server(manifest_at_id)}:8888",
        :username => username,
        :password => password,
        :license => license,
        :collection => cdm_collection(manifest_at_id),
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
    if at_id.match(/.*iiif\/info\//)
      at_id.sub(/.*iiif\/info\//, '').sub(/\/\d+\/manifest.json/, '')
    elsif at_id.match(/.*iiif\/2\//)
      at_id.sub(/.*iiif\/2\//, '').sub(/:.*/,'')
    else # match https://cdm17168.contentdm.oclc.org/iiif/WFP:997/manifest.json
      at_id.sub(/.*iiif\//, '').sub(/:.*/,'')
    end
  end

  def self.cdm_record(at_id)
    at_id.sub(/\/canvas\/.*/,'').sub(/^.*\//, '').sub(/^.*:/, '')
  end

  def self.get_cdm_host_from_url(host)
    matches = host.match(/https?:\/\/(cdm\d+)/)
    return matches[1] if matches

    res = URI.open("#{host}/iiif/info/manifest.json").read
    res_json = JSON.parse(res)
    url = res_json['@id'] || nil

    if url
      matches = url.match(/https?:\/\/(cdm\d+)/)
      return matches[1] if matches
    end
    nil
  end

  def self.cdm_url_to_iiif(url)
    uri = URI(url)

    server = get_cdm_host_from_url("#{uri.scheme}://#{uri.host}")
    raise "ContentDM URLs must be of the form http://cdmNNNNN.contentdm.oclc.org/..." if server.nil?

    matches = uri.path.match(/.*collection\/(\w+)(?:\/id\/(\d+))?/)
    
    if matches
      collection = matches[1]
      record = matches[2]
    end
    
    # support back-level CONTENTdm IIIF presentation implementation
    if server && collection && record
      new_uri = "https://#{server}.contentdm.oclc.org/iiif/info/#{collection}/#{record}/manifest.json"
    elsif server && collection
      new_uri = "https://#{server}.contentdm.oclc.org/iiif/info/#{collection}/manifest.json"
    elsif server
      new_uri = "https://#{server}.contentdm.oclc.org/iiif/info/manifest.json"
    else
      raise "ContentDM URLs must be of the form http://cdmNNNNN.contentdm.oclc.org/..."
    end

    begin
      URI.open(new_uri)
    rescue OpenURI::HTTPError
      if server && collection && record
        # https://cdm17217.contentdm.oclc.org/iiif/2/voter1867:4764/manifest.json
        new_uri = "https://#{server}.contentdm.oclc.org/iiif/2/#{collection}:#{record}/manifest.json"
      elsif server && collection
        # https://cdm17217.contentdm.oclc.org/iiif/2/voter1867/manifest.json
        new_uri = "https://#{server}.contentdm.oclc.org/iiif/2/#{collection}/manifest.json"
      else
        # https://cdm17217.contentdm.oclc.org/iiif/2/manifest.json
        new_uri = "https://#{server}.contentdm.oclc.org/iiif/2/manifest.json"
      end

    end

    new_uri
  end

  def self.sample_manifest(collection)
    imported_work = collection.works.joins(:sc_manifest).last

    imported_work && imported_work.sc_manifest
  end
end
