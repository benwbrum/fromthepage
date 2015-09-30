require 'iiif/presentation'
class IiifController < ApplicationController
  def collection
    render :text => 'this would be the collection manifest'
  end
    
  def manifest
    work_id =  params[:id]


    work = Work.find work_id
    seed = { '@id' => 'http://localhost:3000/display/read_work?work_id=#{work.id}', 'label' => work.title}
    manifest = IIIF::Presentation::Manifest.new(seed)
    manifest.label = work.title

    sequence = IIIF::Presentation::Sequence.new
    sequence.label = 'Pages'
    
    work.pages.each do |page|
      image_resource = IIIF::Presentation::ImageResource.create_image_api_image_resource(
        {
          :service_id => "http://localhost:3000/image-service/#{page.id}", 
          :resource_id => "http://localhost:3000/image-service/#{page.id}/full/full/0/native.jpg",
          :height => page.base_height,
          :width => page.base_width,
          :profile => 'http://library.stanford.edu/iiif/image-api/1.1/compliance.html#level2'
         })
      annotation = IIIF::Presentation::Annotation.new
      annotation.resource << image_resource

      canvas = IIIF::Presentation::Canvas.new
      canvas.label = page.title
      canvas.width = page.base_width
      canvas.height = page.base_height
      canvas['@id'] = "http://localhost:3000/image-service/#{page.id}"
      canvas.images << annotation

      sequence.canvases << canvas      
    end

    manifest.sequences << sequence

    render :text => manifest.to_json(pretty: true), :content_type => "application/json"
  end
    
  
end
