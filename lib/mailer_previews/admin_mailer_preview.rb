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

end
