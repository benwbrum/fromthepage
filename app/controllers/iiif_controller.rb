require 'iiif/presentation'
class IiifController < ApplicationController
  before_action :set_cors_headers
  
  def collections
    site_collection = IIIF::Presentation::Collection.new
    site_collection['@id'] = url_for({:controller => 'iiif', :action => 'collections', :only_path => false})
    site_collection.label = "IIIF resources avaliable on the FromThePage installation at #{Rails.application.config.action_mailer.default_url_options[:host]}."
    site_collection.metadata << { "label" => "FromThePage Support for IIIF", "value" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations"}

    Collection.where(:restricted => false).each do |collection|
      iiif_collection = iiif_collection_from_collection(collection,false)

      site_collection.collections << iiif_collection
    end

    render :text => site_collection.to_json(pretty: true), :content_type => "application/json"
  end

  def collection
    iiif_collection = iiif_collection_from_collection(@collection,true)

    render :text => iiif_collection.to_json(pretty: true), :content_type => "application/json"
  end

  def contributions
    domain = params[:domain]
    raw_terminus_a_quo = params[:terminus_a_quo]
    raw_terminus_ad_quem = params[:terminus_ad_quem]
    
    terminus_a_quo = nil
    terminus_ad_quem = nil
    # error processing -- return 400 Bad Request with explanatory text in HTML or JSON within a respond_to
    # see https://cloud.google.com/storage/docs/json_api/v1/status-codes
    if domain.blank?
      render :status => 400, :text => "Usage: {url}/iiif/contributions/<b><i>domain</i></b>/<i>beginning of window</i>/<i>end of window</i><br />See <a href=\"https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations\">docs</a> for more help."
      return
    end      
    
    begin
      terminus_a_quo = DateTime.parse(raw_terminus_a_quo) if raw_terminus_a_quo
    rescue
      render :status => 400, :text => "Could not parse #{raw_terminus_a_quo} as a date. Try a format like #{DateTime.now.iso8601}"
      return
    end
    begin
      terminus_ad_quem =     DateTime.parse(raw_terminus_ad_quem) if raw_terminus_ad_quem    
    rescue
      render :status => 400, :text => "Could not parse #{raw_terminus_ad_quem} as a date. Try a format like #{DateTime.now.iso8601}"
      return      
    end
    contributions = collection_for_domain(domain, terminus_a_quo, terminus_ad_quem)
    render :text => contributions.to_json(pretty: true), :content_type => "application/json"
  end

  def for
    at_id = params[:id]
    if at_id.match /https?:\/\w/
      at_id.sub!(":/", "://")
    end
    if sc_collection = ScCollection.where(:at_id => at_id).last
      redirect_to :controller => 'iiif', :action => 'collection', :collection_id => sc_collection.collection_id
      return
    end

    if sc_manifest = ScManifest.where(:at_id => at_id).last
      redirect_to({:controller => 'iiif', :action => 'manifest', :id => sc_manifest.work_id, :only_path => false})
      return
    end

    if sc_canvas = ScCanvas.where(:sc_canvas_id => at_id).last
      redirect_to :controller => 'iiif', :action => 'canvas', :page_id => sc_canvas.page_id
      return
    end    

    if at_id.match(/http/)   
      render :status => 404, :text => "No items that correspond to #{at_id} have been imported into the FromThePage server.  For a full list of public IIIF resources, see #{url_for(:controller => 'iiif', :action => 'collections')}"
    else
      collection_for_domain(at_id)
    end
  end
  
  def collection_for_domain(domain, terminus_a_quo = nil, terminus_ad_quem = nil)
    if terminus_a_quo && terminus_ad_quem
      works = Work.joins(:deeds, :sc_manifest).where("sc_manifests.at_id LIKE ?", "%#{domain}%").where(:deeds => { :created_at => terminus_a_quo..terminus_ad_quem, :deed_type => Deed::CONTRIBUTOR_DEED_TYPES}).distinct
    elsif terminus_a_quo
      works = Work.joins(:deeds, :sc_manifest).where("sc_manifests.at_id LIKE ? AND deeds.created_at >= ? AND deeds.deed_type != '#{Deed::WORK_ADDED}'", "%#{domain}%", terminus_a_quo).distinct      
    else
      works = Work.joins(:sc_manifest).where("at_id LIKE ?", "%#{domain}%")
    end

    domain_collection = IIIF::Presentation::Collection.new
    domain_collection['@id'] = url_for({:controller => 'iiif', :action => 'for', :id => domain, :only_path => false})
    domain_collection.label = "IIIF resources avaliable on the FromThePage installation at #{Rails.application.config.action_mailer.default_url_options[:host]} which were derived from resources matching *#{domain}*"
      
    works.each do |work|
      seed = { 
                '@id' => url_for({:controller => 'iiif', :action => 'manifest', :id => work.id, :only_path => false}), 
                'label' => work.title                
            }
      manifest = IIIF::Presentation::Manifest.new(seed)
      manifest.label = work.title
      manifest.metadata = [{"label" => "dc:source", "value" => work.sc_manifest.at_id }]
      manifest.service = status_service_for_manifest(work)
    
      domain_collection.manifests << manifest            
    end

    domain_collection        
  end

  def manifest
    work_id =  params[:id]
    work = Work.find work_id
    seed = {
              '@id' => url_for({:controller => 'iiif', :action => 'manifest', :id => work_id, :only_path => false}),
              'label' => work.title
            }
    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest.label = work.title
    dc_source = dc_source_from_work(work)
    manifest.metadata = [dc_source] if dc_source
      
    if work.sc_manifest
      manifest.description = "This is an annotated version of the original manifest produced by FromThePage"
    else
      manifest.description = work.description unless work.description.blank?
    end
    manifest.within = {
      "@type" => "sc:Collection",
      "label" => work.collection.title,
      "@id" => iiif_collection_id_from_collection(work.collection)
    }
    manifest.related = [
      {
        "format" => "text/html",
        "label" => "Read #{work.title}",
        "@id" => collection_read_work_path(work.collection.owner, work.collection, work)
      },
      {
        "format" => "text/html",
        "label" => "Table of Contents for #{work.title}",
        "@id" => collection_work_contents_path(work.collection.owner, work.collection, work)
      }
    ]
    
    manifest.seeAlso = []
    manifest.seeAlso << 
    { "label" => "Verbatim Plaintext", 
      "format" => "text/plain", 
      "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#verbatim-plaintext-1", 
      "@id" => collection_work_export_plaintext_verbatim_path(work.collection.owner, work.collection, work, :only_path => false) 
    }
    manifest.seeAlso << 
    { "label" => "Emended Plaintext", 
      "format" => "text/plain", 
      "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#emended-plaintext", 
      "@id" => collection_work_export_plaintext_emended_path(work.collection.owner, work.collection, work, :only_path => false)
    }
    if work.supports_translation?
      manifest.seeAlso << 
      { "label" => "Verbatim Translation Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#verbatim-translation-plaintext", 
        "@id" => collection_work_export_plaintext_translation_verbatim_path(work.collection.owner, work.collection, work, :only_path => false)
      }
      manifest.seeAlso << 
      { "label" => "Emended Translation Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#emended-translation-plaintext", 
        "@id" => collection_work_export_plaintext_translation_emended_path(work.collection.owner, work.collection, work, :only_path => false)
      }
    end    
    manifest.seeAlso << 
      { "label" => "Searchable Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#plaintext-for-full-text-search", 
        "@id" => collection_work_export_plaintext_searchable_path(work.collection.owner, work.collection, work, :only_path => false)
    }
    manifest.service << status_service_for_manifest(work)
    sequence = iiif_sequence_from_work_id(work_id)
    manifest.sequences << sequence

    seed = {
              '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => 'transcription', :only_path => false}),
              'label' => "transcription layer"
            }
    layer = IIIF::Presentation::Layer.new(seed)
    manifest["otherContent"] = [layer]

    if work.supports_translation?
      seed = {
              '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => 'translation', :only_path => false}),
              'label' => "translation layer"
            }
      layer = IIIF::Presentation::Layer.new(seed)
      manifest["otherContent"]  << layer
    end

    if true #any notes
      seed = {
              '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => 'notes', :only_path => false}),
              'label' => "notes layer"
            }
      layer = IIIF::Presentation::Layer.new(seed)
      manifest["otherContent"]  << layer
    end
    
    render :text => manifest.to_json(pretty: true), :content_type => "application/json"
  end

  def canvas
    if @page.sc_canvas
      render :text => canvas_from_iiif_page(@page).to_json(pretty: true), :content_type => "application/json"
    else
      render :text => canvas_from_page(@page).to_json(pretty: true), :content_type => "application/json"
    end
  end

  def list
    type = params[:annotation_type]
    if type == 'notes'  #notes need to be handled separately
      notes
      return
    end
    annotation_list = IIIF::Presentation::AnnotationList.new
    annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => @page.id, :annotation_type => type, :only_path => false})

    annotation = iiif_annotation_by_type(@page.id,type)

    annotation_list.resources << annotation
    render :text => annotation_list.to_json(pretty: true), :content_type => "application/json"
  end

  def layer
    work_id = params[:id]
    work = Work.find work_id
    #params[:type]
    if params[:type]=="transcription"
      seed = {
                '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => params[:type], :only_path => false}),
                'label' => params[:type] + " layer"
              }
      layer = IIIF::Presentation::Layer.new(seed)
      layer["otherContent"]=[]
      work.pages.each do |page|
        annotation_list = annotationlist_from_page(page, params[:type])
        if annotation_list
          layer["otherContent"] << annotation_list
        end
      end
    end

   if work.supports_translation? && params[:type]=="translation"
      seed = { 
              '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => 'translation', :only_path => false}), 
              'label' => "Translation"
            }
      layer = IIIF::Presentation::Layer.new(seed)
      layer["otherContent"] = []
      work.pages.each do |page|
        annotation_list = annotationlist_from_page(page, params[:type])
        if annotation_list
          layer["otherContent"] << annotation_list
        end
      end
    end

   if params[:type]=="notes"
      seed = { 
                '@id' => url_for({:controller => 'iiif', :id => work_id, :action => 'layer', :type => params[:type], :only_path => false}), 
                'label' => params[:type].titlize + " layer"
              }
      layer = IIIF::Presentation::Layer.new(seed)
      layer["otherContent"]=[]
      work.pages.each do |page|
        unless page.notes.empty?
          annotation_list = annotationlist_from_page(page, params[:type])
          if annotation_list
            layer["otherContent"] << annotation_list
          end
        end
      end
    end

    render :text => layer.to_json(pretty: true), :content_type => "application/json"
  end

  def sequence
    work_id = @work.id
    sequence = iiif_sequence_from_work_id(work_id)
    render :text => sequence.to_json(pretty: true), :content_type => "application/json"
  end

  def annotation
    page_id = params[:page_id]
    type = params[:annotation_type]
    annotation = iiif_annotation_by_type(page_id,type)
    annotation['@id'] = url_for({:controller => 'iiif', :action => 'annotation', :page_id => @page.id, :annotation_type => type, :only_path => false})
    render :text => annotation.to_json(pretty: true), :content_type => "application/json"
  end

  def notes
    page = Page.find params[:page_id]
    annotation_list = IIIF::Presentation::AnnotationList.new
    annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'notes', :page_id => @page.id, :only_path => false})
    @page.notes.each_with_index do |note, i|
      note = iiif_page_note(@page,i+1)
      note['@id'] = url_for({:controller => 'iiif', :action => 'note', :page_id => @page.id, :note_id => i+1, :only_path => false})
      annotation_list.resources << note
    end
    render :text => annotation_list.to_json(pretty: true), :content_type => "application/json"
  end

  def note
    noteid = params[:note_id].to_i
    page = Page.find params[:page_id]
    note = iiif_page_note(@page,noteid)
    note['@id'] = url_for({:controller => 'iiif', :action => 'note', :page_id => @page.id, :note_id => noteid, :only_path => false})
    render :text => note.to_json(pretty: true), :content_type => "application/json"
  end

  def canvas_status
    page = Page.find params[:page_id]
    service = status_service_for_page(page)
    render :text => service.to_json(pretty: true), :content_type => "application/json"
  end
  
  def manifest_status
    work = Work.find params[:work_id]
    service = status_service_for_work(work)
    render :text => service.to_json(pretty: true), :content_type => "application/json"    
  end

private
  def iiif_page_note(page, noteid)
    note = IIIF::Presentation::Annotation.new
    #note['@id'] = url_for({:controller => 'iiif', :action => 'note', :page_id => @page.id, :note_id => noteid, :only_path => false})
    note['on'] = region_from_page(@page)
    note.resource = IIIF::Presentation::Resource.new({'@id' => "note_#{noteid}_for_#{@page.id}", '@type' => "cnt:ContentAsText"})
    note.resource["format"] =  "text/plain"
    note.resource["chars"] = @page.notes[noteid.to_i-1].body
    note
  end

  def iiif_annotation_by_type(page_id, type)
    annotation = IIIF::Presentation::Annotation.new
    page = Page.find page_id
    case type
    when 'transcription'
      annotation['on'] = region_from_page(@page)
      annotation.resource = IIIF::Presentation::Resource.new({'@id' => "plaintext_export_for_#{@page.id}", '@type' => "cnt:ContentAsText"})
      annotation.resource["format"] =  "text/plain"

      doc = Nokogiri::XML(@page.xml_text.gsub(/<\/p>/, "</p>\n\n").gsub("<lb/>", "\n"))
      no_tags = doc.text

      annotation.resource["chars"] = no_tags
    when 'translation'
      unless page.source_translation.blank?
        #annotation = IIIF::Presentation::Annotation.new
        #page = Page.find page_id
        annotation['on'] = region_from_page(@page)
        annotation.resource = IIIF::Presentation::Resource.new({'@id' => "translation_export_for_#{@page.id}", '@type' => "cnt:ContentAsText"})
        annotation.resource["format"] =  "text/plain"

        doc = Nokogiri::XML(@page.xml_translation.gsub(/<\/p>/, "</p>\n\n").gsub("<lb/>", "\n"))
        no_tags = doc.text

        annotation.resource["chars"] = no_tags
      end
    when 'facsimile'
      #annotation = IIIF::Presentation::Annotation.new
      #page = Page.find page_id
      annotation.resource = iiif_create_image_resource(page)
      annotation['on'] = region_from_page(@page)
    when type.match(/comment/)  #starts with comment?
      #do something
    end
    annotation
  end

  def iiif_image_annotation_from_work_id(work_id)
    annotation
  end

  def iiif_sequence_from_work_id(work_id)
    sequence = IIIF::Presentation::Sequence.new
    sequence['@id'] = url_for({:controller => 'iiif', :action => 'sequence', :work_id => work_id, :sequence_name => 'default', :only_path => false})
    sequence.label = 'Pages'
    work = Work.includes(:pages => [:sc_canvas, :notes]).where(id: work_id).first
    sequence['rendering'] = [
      { "label" => "Verbatim Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#verbatim-plaintext", 
        "@id" => collection_work_export_plaintext_verbatim_path(work.collection.owner, work.collection, work, :only_path => false) 
      },
      { "@id" => url_for(:controller => :export, :action => :show, :work_id => work.id), "label" => "XHTML Export", "profile" => "XHTML URL"},     
      { "@id" => url_for(:controller => :export, :action => :tei, :work_id => work.id), "label" => "TEI Export", "profile" => "tei URL"}
    ]
    pages = work.pages
    pages.each do |page|
      if page.sc_canvas
        sequence.canvases << canvas_from_iiif_page(page)
      else
        sequence.canvases << canvas_from_page(page)
      end
    end
    sequence
  end

  def iiif_collection_id_from_collection(collection)
    url_for({ :controller => 'iiif', :action => 'collection', :collection_id => collection.id, :only_path => false })
  end

  def iiif_collection_from_collection(collection,depth)
    iiif_collection = IIIF::Presentation::Collection.new
    iiif_collection.label = collection.title
    iiif_collection['@id'] = iiif_collection_id_from_collection(collection)
    if collection.sc_collection
      iiif_collection.metadata = [{"label" => "dc:source", "value" => collection.sc_collection.at_id }]
    end

    if depth == true
      collection.works.each do |work|
        unless work.ia_work
          seed = {
                    '@id' => url_for({:controller => 'iiif', :action => 'manifest', :id => work.id, :only_path => false}),
                    'label' => work.title
                }
          manifest = IIIF::Presentation::Manifest.new(seed)
          manifest.label = work.title
          dc_source = dc_source_from_work(work)
          manifest.metadata = [dc_source] if dc_source
          manifest.service = status_service_for_manifest(work)
        
          iiif_collection.manifests << manifest            
        end
      end
    end
    iiif_collection
  end

  def dc_source_from_work(work)
    dc_source = nil
    if !work.identifier.blank? || work.sc_manifest
      dc_source = {"label" => "dc:source"}
      if work.identifier && work.sc_manifest
        dc_source["value"] = [work.identifier, work.sc_manifest.at_id]
      else
        if work.sc_manifest
          dc_source["value"] = work.sc_manifest.at_id
        else
          dc_source["value"] = work.identifier
        end
      end
    end
    dc_source
  end

  def canvas_id_from_page(page)
    if page.sc_canvas
      page.sc_canvas.sc_canvas_id
    else
      url_for({ :controller => 'iiif', :action => 'canvas', :page_id => page.id, :work_id => page.work.id, :only_path => false })
    end
  end

  def region_from_page(page)
    canvas_id_from_page(page) + "#xywh=0,0,#{(page.base_width || page.sc_canvas.width)},#{(page.base_height || page.sc_canvas.height)}"
  end

  def iiif_create_image_resource(page)
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      {
        :service_id => "#{url_for(:root)}image-service/#{page.id}", 
        :resource_id => "#{url_for(:root)}image-service/#{page.id}/full/full/0/default.jpg",
        :height => page.base_height,
        :width => page.base_width,
        :profile => 'http://iiif.io/api/image/2/level1.json',
                
       })
       
    image_resource.service['@context'] = 'http://iiif.io/api/image/2/context.json'
    image_resource
  end

  def iiif_create_iiif_image_resource(page)
    image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
      {
        :service_id => page.sc_canvas.sc_service_id,
        :resource_id => page.sc_canvas.sc_resource_id,
        :height => (page.base_height || page.sc_canvas.height),
        :width => (page.base_width || page.sc_canvas.width),
        :profile => 'http://library.stanford.edu/iiif/image-api/1.1/compliance.html#level2',
       })
    #image_resource.service_id = page.sc_canvas.sc_service_id
    #image_resource.resource_id = page.sc_canvas.sc_resource_id
    #image_resource.service['@context'] = 'http://iiif.io/api/image/1/context.json'

    image_resource.service['@context'] = page.sc_canvas.sc_service_context
    image_resource
  end

  def canvas_from_iiif_page(page)

    canvas = IIIF::Presentation::Canvas.new
    canvas.label = page.title
    canvas.width = page.sc_canvas.width
    canvas.height = page.sc_canvas.height
    canvas['@id'] = canvas_id_from_page(page)

    annotation = IIIF::Presentation::Annotation.new
    annotation.resource = iiif_create_iiif_image_resource(page)
    annotation['on'] = canvas['@id']
    annotation['@id'] = page.sc_canvas.sc_service_id

    canvas.images << annotation

    add_related_to_canvas(canvas, page)
    add_seeAlso_to_canvas(canvas, page)
    add_services_to_canvas(canvas, page)
    add_annotations_to_canvas(canvas, page)

    canvas     
  end

  def canvas_from_page(page)
    canvas = IIIF::Presentation::Canvas.new
    canvas.label = page.title
    canvas.width = page.base_width
    canvas.height = page.base_height
    canvas['@id'] = canvas_id_from_page(page)

    annotation = IIIF::Presentation::Annotation.new
    annotation.resource = iiif_create_image_resource(page)
    annotation['on'] = canvas['@id']
    annotation['@id'] = "#{url_for(:root)}image-service/#{page.id}"
    canvas.images << annotation

    add_related_to_canvas(canvas, page)
    add_seeAlso_to_canvas(canvas, page)
    add_services_to_canvas(canvas, page)

    canvas     
  end

  def add_annotations_to_canvas(canvas,page)
    unless page.source_text.blank?
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => "transcription", :only_path => false})
      annotation_list['label'] = 'Transcription'
      canvas.other_content << annotation_list
    end

    unless page.source_translation.blank?
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => "translation", :only_path => false})
      annotation_list['label'] = 'Translation'
      canvas.other_content << annotation_list
    end

    if page.notes.exists?
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => "notes", :only_path => false})
      annotation_list['label'] = 'Notes'
      canvas.other_content << annotation_list
    end
    canvas
  end
  

  def add_related_to_canvas(canvas,page)
    canvas.related = [] unless canvas.related
    canvas.related << { "label" => "Read this page", "format" => "text/html", "@id" => url_for(:controller => :display, :action => :display_page, :page_id => page.id)}
    canvas.related << { "label" => "Transcribe this page", "format" => "text/html", "@id" => url_for(:controller => :transcribe, :action => :display_page, :page_id => page.id)}
    canvas.related << { "label" => "Translate this page", "format" => "text/html", "@id" => url_for(:controller => :transcribe, :action => :translate, :page_id => page.id)} if page.work.supports_translation?
  end

  def add_services_to_canvas(canvas,page)
    canvas.service = status_service_for_page(page)
  end

  def add_seeAlso_to_canvas(canvas,page)
    canvas.seeAlso = [] unless canvas.seeAlso
    canvas.seeAlso << 
      { "label" => "Searchable Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#plaintext-for-full-text-search-1", 
        "@id" => collection_page_export_plaintext_searchable_path(page.work.collection.owner, page.work.collection, page.work, page.id, :only_path => false)
    }
    canvas.seeAlso << 
    { "label" => "Verbatim Plaintext", 
      "format" => "text/plain", 
      "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#verbatim-plaintext-2", 
      "@id" => collection_page_export_plaintext_verbatim_path(page.work.collection.owner, page.work.collection, page.work, page.id, :only_path => false) 
    }
    canvas.seeAlso << 
    { "label" => "Emended Plaintext", 
      "format" => "text/plain", 
      "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#emended-plaintext-1", 
      "@id" => collection_page_export_plaintext_emended_path(page.work.collection.owner, page.work.collection, page.work, page.id, :only_path => false)
    }
    if page.work.supports_translation?
      canvas.seeAlso << 
      { "label" => "Verbatim Translation Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#verbatim-translation-plaintext-1", 
        "@id" => collection_page_export_plaintext_translation_verbatim_path(page.work.collection.owner, page.work.collection, page.work, page.id, :only_path => false)
      }
      canvas.seeAlso << 
      { "label" => "Emended Translation Plaintext", 
        "format" => "text/plain", 
        "profile" => "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#emended-translation-plaintext-1", 
        "@id" => collection_page_export_plaintext_translation_emended_path(page.work.collection.owner, page.work.collection, page.work, page.id, :only_path => false)
      }
    end
  end

 def annotationlist_from_page(page,type)
  #annotationlists[] = []
  case type
  when 'transcription'
    unless page.source_text.blank?
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => type, :only_path => false})
      annotation_list['label'] = "Transcription"
    end
  when 'translation'
    unless page.source_translation.blank?
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => type, :only_path => false})
      annotation_list['label'] = "Translation"
    end
  when 'notes'
    unless page.notes.blank?   #no comments
      annotation_list = IIIF::Presentation::AnnotationList.new
      annotation_list['@id'] = url_for({:controller => 'iiif', :action => 'list', :page_id => page.id, :annotation_type => type, :only_path => false})
      annotation_list['label'] = "Notes"
    end
  end
    annotation_list
  end

  def status_service_for_manifest(work)
    service = IIIF::Service.new
    service["label"] = "Work Status"
    service["profile"] = "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#service"
    service["@context"] = "http://www.fromthepage.org/jsonld/1/context.json"
    service["@id"] = url_for({:controller => 'iiif', :action => 'manifest_status', :work_id => work.id, :only_path => false})

    stats = work.work_statistic
    total = stats.total_pages

    service["pctComplete"] = stats.pct_completed
    service["pctTranscribed"] = !work.ocr_correction ? stats.pct_completed : 0.0
    service["pctOcrCorrected"] = work.ocr_correction ? stats.pct_completed : 0.0
    service["pctIndexed"] = stats.pct_annotated
    service["pctMarkedBlank"] = stats.pct_blank
    service["pctNeedsReview"] = stats.pct_needs_review
    service["pctTranslationComplete"] = stats.pct_translation_completed
    service["pctTranslated"] = stats.pct_translation_completed
    service["pctTranslationNeedsReview"] = stats.pct_translation_needs_review
    service["pctTranslationIndexed"] = stats.pct_translation_annotated
    service["pctTranslationMarkedBlank"] = stats.pct_translation_blank
    service
  end
  
  def status_service_for_page(page)
    service = IIIF::Service.new
    service["label"] = "Page Status"
    service["profile"] = "https://github.com/benwbrum/fromthepage/wiki/FromThePage-Support-for-the-IIIF-Presentation-API-and-Web-Annotations#service-1"
    service["@context"] = "http://www.fromthepage.org/jsonld/1/context.json"
    service["@id"] = url_for({:controller => 'iiif', :action => 'canvas_status', :work_id => page.work.id, :page_id => page.id, :only_path => false})    
    service["pageStatus"] = []
    service["pageStatus"] << "needsReview" if page.status == Page::STATUS_NEEDS_REVIEW
    service["pageStatus"] << "ocrCorrected" if page.work.ocr_correction && (page.status == Page::STATUS_NEEDS_REVIEW || page.status == Page::STATUS_TRANSCRIBED)
    service["pageStatus"] << "markedBlank" if page.status == Page::STATUS_BLANK
    service["pageStatus"] << "hasTranscript" if page.status == Page::STATUS_NEEDS_REVIEW || page.status == Page::STATUS_TRANSCRIBED
    service["pageStatus"] << "hasTranslation" if page.translation_status == Page::STATUS_NEEDS_REVIEW || page.translation.status == Page::STATUS_TRANSLATED
    service["pageStatus"] << "hasSubjectTags" if page.status == Page::STATUS_INDEXED
    service
  end

  def format_pct(numerator, denominator)
    raw = numerator * 100.0 / denominator
    raw.round(1)
  end

  def set_cors_headers    
    headers['Access-Control-Allow-Origin'] = '*'
#    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end
end
