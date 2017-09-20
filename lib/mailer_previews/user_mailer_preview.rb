class UserMailerPreview < ActionMailer::Preview

  def iiif_collection_import_failed
    manifests = ScManifest.last(5)
    errors = {}
    manifests.each do |m|
      errors.store(m.at_id, m.label)
    end
    UserMailer.iiif_collection_import_failed(916, 168, errors)
  end

  def iiif_collection_import_succeeded
    UserMailer.iiif_collection_import_succeeded(916, 168)
  end
  
end
