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
  
  
  
end