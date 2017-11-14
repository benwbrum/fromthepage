class AdminMailerPreview < ActionMailer::Preview
  
  def contributor_stats
    AdminMailer.contributor_stats(1, 2.weeks.ago, Time.now, ADMIN_EMAILS)
  end
  
  def email_stats
    AdminMailer.email_stats(48)
  end
  
  def collection_stats_by_owner
    owner = User.find_by(login: 'admin')
    AdminMailer.collection_stats_by_owner(owner, 1.day.ago, DateTime.now.utc)
  end

  def iiif_collection_import_failed
    manifests = ScManifest.last(5)
    errors = {}
    manifests.each do |m|
      errors.store(m.at_id, m.label)
    end
    AdminMailer.iiif_collection_import_failed(916, 168, errors)
  end

  def iiif_collection_import_succeeded
    AdminMailer.iiif_collection_import_succeeded(916, 168)
  end
  
end
