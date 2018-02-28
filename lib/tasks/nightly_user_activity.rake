namespace :fromthepage do
  desc "nightly collection activity sent to users"
  task :nightly_user_activity => :environment do
    #find collections where works have been added
    collections = Collection.joins(:deeds).where(deeds: {deed_type: 'work_add'}).merge(Deed.past_day).distinct
    #find edited pages
    active_pages = Page.joins(:deeds).merge(Deed.past_day).distinct
    #find users with edited pages or added works
    #note that injecting this query allows us to use or and get an active record relation, which isn't available in Rails 4.1.2
    query = Deed.where('page_id in (?) or collection_id = ?', active_pages.ids, collections.ids)
    all_users = User.joins(:deeds).where(query.where_values.inject(:or)).joins(:notification).where(notifications: {user_activity: true}).distinct
    #pass users to mailer
    if SMTP_ENABLED
      all_users.each do |user|
        puts "There was activity on #{user.display_name}\'s previous work in the past 24 hours"
        begin
          UserMailer.nightly_user_activity(user).deliver!
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message} \n"
        end
      end
    end
  end

end
