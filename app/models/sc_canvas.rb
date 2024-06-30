# == Schema Information
#
# Table name: sc_canvases
#
#  id                 :integer          not null, primary key
#  annotations        :text(16777215)
#  height             :integer
#  sc_canvas_label    :string(255)
#  sc_service_context :string(255)
#  width              :integer
#  created_at         :datetime
#  updated_at         :datetime
#  page_id            :integer
#  sc_canvas_id       :string(255)
#  sc_id              :string(255)
#  sc_manifest_id     :integer
#  sc_resource_id     :string(255)
#  sc_service_id      :string(255)
#
# Indexes
#
#  index_sc_canvases_on_page_id         (page_id)
#  index_sc_canvases_on_sc_manifest_id  (sc_manifest_id)
#
class ScCanvas < ApplicationRecord
  self.table_name = "sc_canvases"

  belongs_to :sc_manifest, optional: true
  belongs_to :page, optional: true

  def thumbnail_url
    if sc_service_id
      service_id = sc_service_id.sub(/\/$/,'')
      if sc_service_context ==  "http://iiif.io/api/image/1/context.json"
        "#{service_id}/full/100,/0/native.jpg"
      else
        "#{service_id}/full/100,/0/default.jpg"
      end
    else
      sc_resource_id
    end
  end

  def facsimile_url
    if sc_service_id
      "#{sc_service_id}/full/full/0/default.jpg"
    else
      sc_resource_id
    end
  end


  def transcript_annotations
    return nil unless self.annotations

    annotation_list = JSON.parse(self.annotations)
    transcript_list = annotation_list.detect do |element|
      # Use the page-level annotation if possible
      element['data']['@type'] == "sc:AnnotationList" && element['data']["textGranularity"] == "page"
    end
    unless transcript_list
      # Use any annotation list if not
      transcript_list = annotation_list.detect do |element|
        element['data']['@type'] == "sc:AnnotationList"
      end
    end

    transcript_list
  end

  def has_annotation?
    transcript_annotations
  end

  def annotation_text_for_source
    transcript_list = transcript_annotations
    resource_format = transcript_list['data']['resources'].first['data']['resource']['data']['format']
    resource_contents = transcript_list['data']['resources'].first['data']['resource']['data']['chars']

    if resource_format == 'text/html'
      doc = Nokogiri::HTML(resource_contents)
      doc.search('br').each { |node| node.replace("\n") }
      transcript = doc.text
    else
      transcript = resource_contents
    end
    transcript
  end

end
