def new_to_old_manifest(at_id)
  at_id.sub('/2/', '/info/').sub(/:(\d)/, '/\1')
end

def new_to_old_image(at_id)
  at_id.sub('/iiif/2/', '/digital/iiif/').sub(/:(\d)/, '/\1')
end

namespace :fromthepage do
  desc 'Remediates bad CDM imports'
  task remediate_cdm_manifests: :environment do |t, args|
    ScManifest.where("at_id like '%oclc.org/iiif/2%'").each do |sc_manifest|
      # test the id
      new_style_id = sc_manifest.at_id
      old_style_id = new_to_old_manifest(new_style_id)
      #
      begin
        URI.open(old_style_id)
        # actually migrate the data
        sc_manifest.at_id = old_style_id
        sc_manifest.save!

        sc_manifest.sc_canvases.each do |sc_canvas|
          # change service_id and resource_id
          sc_canvas.sc_resource_id = new_to_old_image(sc_canvas.sc_resource_id)
          sc_canvas.sc_service_id = new_to_old_image(sc_canvas.sc_service_id)

          sc_canvas.save!
        end
      rescue OpenURI::HTTPError
        print "No old-style URI for #{old_style_id}\n"
      end
    end
  end
end
