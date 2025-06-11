# == Schema Information
#
# Table name: sc_manifests
#
#  id                   :integer          not null, primary key
#  first_sequence_label :string(255)
#  label                :text(65535)
#  metadata             :text(65535)
#  version              :string(255)      default("2")
#  created_at           :datetime
#  updated_at           :datetime
#  at_id                :string(255)
#  collection_id        :integer
#  first_sequence_id    :string(255)
#  sc_collection_id     :integer
#  sc_id                :string(255)
#  work_id              :integer
#
# Indexes
#
#  index_sc_manifests_on_sc_collection_id  (sc_collection_id)
#  index_sc_manifests_on_work_id           (work_id)
#
class ScManifest < ApplicationRecord
  belongs_to :work, optional: true
  belongs_to :sc_collection, optional: true
  belongs_to :collection, optional: true

  has_many :sc_canvases

  attr_accessor :service
  attr_accessor :v3_hash


  def self.manifest_for_at_id(at_id)
    connection = URI.open(at_id)
    manifest_json = connection.read
    #manifest_json = TEST_MANIFEST
    service = IIIF::Service.parse(manifest_json)

    if service['@type'] == "sc:Collection"
      raise ArgumentError, "#{at_id} contains a collection, not an item"
    end
    sc_manifest = ScManifest.new
    sc_manifest.at_id = at_id
    sc_manifest.label = ScManifest.cleanup_label(service.label)
    sc_manifest.service = service

    sc_manifest
  end

  def self.manifest_for_v3_hash(v3)
    if v3.is_a? String
      v3 = JSON.parse(v3)
    end
    sc_manifest = ScManifest.new
    sc_manifest.at_id = v3['id']
    sc_manifest.label = v3['label'].values.first.first
    sc_manifest.metadata = v3['metadata']
    sc_manifest.v3_hash = v3
    sc_manifest.version = '3'

    sc_manifest
  end

  def v3?
    self.version == '3'
  end

  def requiredStatement
    if v3?
      v3_hash['requiredStatement']
    else
      ""
    end
  end


  def metadata
    if v3?
      v3_hash['metadata']
    else
      service.metadata
    end
  end

  def description
    if v3?
      summary = v3_hash['summary']
      if summary.blank?
        ""
      else
        ScManifest.pluck_language_value v3_hash['summary']
      end
    else
      service.description
    end

  end

  def convert_with_sc_collection(user, sc_collection, annotation_ocr)
    collection = sc_collection.collection
    unless collection
      collection = Collection.new
      collection.owner = user
      collection.title = cleanup_label(sc_collection.label)
      collection.save!
      sc_collection.collection = collection
      sc_collection.save!
    end
    convert_with_collection(user, collection, nil, annotation_ocr)
  end

  def convert_with_no_collection(user, annotation_ocr)
    collection = Collection.new
    collection.owner = user
    collection.title = self.label.truncate(255, separator: ' ', omission: '')
    collection.save!
    convert_with_collection(user, collection, nil, annotation_ocr)
  end

  def items
    if self.v3?
      @v3_hash['items']
    else
      self.service.sequences.first.canvases
    end
  end

  def convert_with_collection(user, collection, document_set=nil, annotation_ocr=false)
    self.save!

    work = Work.new
    work.owner = user
    work.title = self.label
    work.description = self.html_description
    work.collection = collection
    if self.metadata
      work.original_metadata = normalize_metadata(self.metadata).to_json
    end
    work.ocr_correction=annotation_ocr

    work.save!

    unless self.items.empty?
      self.items.each do |canvas|
        sc_canvas = manifest_canvas_to_sc_canvas(canvas)
        page = sc_canvas_to_page(sc_canvas, annotation_ocr)
        work.pages << page
        sc_canvas.page = page
        sc_canvas.save!
      end
    end
    work.save!
    record_deed(work)

    self.work = work
    self.save!

    if document_set
      document_set.works << work
    end

    work
  end

  def self.cleanup_label(label)
    label = flatten_element(label)
    new_label = label.truncate(255, separator: ' ', omission: '')
    new_label.gsub!("&quot;", "'")
    new_label.gsub!("&amp;", "&")
    new_label.gsub!("&apos;", "'")

    new_label
  end


  def self.pluck_language_value(raw)
    if raw.is_a? Hash
      raw = raw.values.first
      if raw.is_a? Array
        raw = raw.first
      end
    end
    raw
  end

  def normalize_metadata(raw)
    if (raw)
      raw.map do |hash|
        # test for v3-style elements
        label = hash['label'] || hash['@label']
        label= ScManifest.pluck_language_value(label)
        value = hash['value'] || hash['@value']
        value = ScManifest.pluck_language_value(value)
        { 'label' => label, 'value' => value}
      end
    end
  end

  def self.flatten_element(element)
    if element.is_a? Array
      element = element.first
    end
    if element.is_a? Hash
      element = element['@value'] || element['value']
    end
    element
  end


  def sc_canvas_to_page(sc_canvas, annotation_ocr=false)
    page = Page.new
    page.title = ScManifest.flatten_element(sc_canvas.sc_canvas_label)
    if annotation_ocr && sc_canvas.has_annotation?
      page.source_text=sc_canvas.annotation_text_for_source
    end

    page
  end


  def has_annotations?
    return false if v3?

    self.service.sequences.first.canvases.detect do |canvas|
      canvas.other_content && canvas.other_content.detect { |e| e['@type'] == "sc:AnnotationList" }
    end
  end

  def manifest_canvas_to_sc_canvas(canvas)
    sc_canvas = ScCanvas.new
    sc_canvas.sc_manifest =             self
    if self.v3?
      annotation_page = canvas['items'].first
      annotation = annotation_page['items'].first
      body = annotation['body']
      if body['service']
        image_service = body['service'].first
      else
        image_service = nil
      end

      sc_canvas.sc_canvas_id =            canvas['id']
      if image_service
        sc_canvas.sc_service_id =           image_service['@id'] || image_service['id']
        sc_canvas.sc_service_context =      image_service['profile']
      end
      sc_canvas.sc_resource_id =          body['id']
      sc_canvas.sc_canvas_label =         ScManifest.pluck_language_value(canvas['label'])
      sc_canvas.height =                  canvas['height']
      sc_canvas.width =                   canvas['width']
    else
      sc_canvas.sc_canvas_id =            canvas['@id']
      sc_canvas.sc_service_id =           canvas.images.first.resource.service['@id']
      sc_canvas.sc_resource_id =          canvas.images.first.resource['@id']
      sc_canvas.sc_service_context = canvas.images.first.resource.service['@context']
      sc_canvas.sc_canvas_label =         canvas.label
      sc_canvas.height = canvas.height
      sc_canvas.width = canvas.width
      if canvas.other_content && canvas.other_content.detect { |e| e['@type'] == "sc:AnnotationList" }
        sc_canvas.annotations = canvas.other_content.to_json
      end
    end

    sc_canvas.save!
    sc_canvas
  end

  def html_description
    description=self.description
    unless description.blank?
      description = ScManifest.flatten_element(self.description) + "\n<br /><br />\n"
    end

    description
  end


  def self.lang_keys_from_hash(hash)
    # expecting label/value pairs
    hash.first[1].keys
  end


  def self.lang_keys_from_object(object)
    lang_keys = []
    if object.is_a? Array
      lang_keys = object.map{ |hash| lang_keys_from_hash(hash) }.flatten
    else
      lang_keys = lang_keys_from_hash(object)
    end
    lang_keys.tally
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
