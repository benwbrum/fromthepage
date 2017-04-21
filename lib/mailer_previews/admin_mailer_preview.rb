class AdminMailerPreview < ActionMailer::Preview
  
  def contributor_stats
    AdminMailer.contributor_stats(63, 2.weeks.ago, Time.now, 'trishablewis@gmail.com')
  end
  
  def email_stats
    AdminMailer.email_stats(300)
  end
  
  def collection_stats_by_owner
    owner = User.find_by(id: 709)
    AdminMailer.collection_stats_by_owner(owner, 1.day.ago, DateTime.now.utc)
  end

end
