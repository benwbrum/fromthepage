namespace :fromthepage do
  desc "nightly collection activity sent to users"
  task :nightly_user_activity => :environment do
    #find added works and get collection ids

    added_works = Work.joins(:deeds).where(deeds: {deed_type: 'work_add'}).merge(Deed.past_day).distinct
    col_ids = added_works.pluck(:collection_id)
    #get all users from collection
    works_users = User.joins(:deeds).where(deeds: {collection_id: col_ids}).joins(:notification).where(notifications: {work_added: true}).distinct
    #find edited pages
    active_pages = Page.joins(:deeds).where(deeds: {deed_type: ['page_edit', 'page_index', 'ocr_corr']}).merge(Deed.past_day).distinct
    #get users from edited pages
    page_users = User.joins(:deeds).where(deeds: {page_id: active_pages.ids}).where(deeds: {deed_type: ['page_trans', 'page_edit', 'page_index', 'ocr_corr']}).joins(:notification).where(notifications: {page_edited: true}).distinct
    #combine user lists
    all_users = (works_users + page_users).uniq
    #for each user, get added works and edited pages then pass to mailer
    if SMTP_ENABLED
      all_users.each do |user|
        if works_users.include?(user) && user.notification.work_added
          #find the collections this user has worked in
          user_col_ids = user.deeds.pluck(:collection_id).uniq
          #find which of the new works are in collections the user has contributed to but that the user hasn't uploaded themselves
          works = added_works.where.not(deeds: {user_id: user.id}).where(collection_id: user_col_ids)
        end
        if page_users.include?(user) && user.notification.page_edited
          #find which pages the user has worked on
          user_page_ids = user.deeds.pluck(:page_id).uniq
          #find pages that have been newly edited by someone other than the user
          pages = active_pages.where.not(deeds: {user_id: user.id}).where(id: user_page_ids)
        end
        puts "#{user.display_name} -- #{works} -- #{pages}"
        unless works.nil?
          works.each do |work|
            puts "#{user.display_name} - has worked in collection where #{work.title} was added"
          end
        end
        unless pages.nil?
          pages.each do |page|
            puts "#{user.display_name} has worked on page #{page.title} in collection #{page.collection.title}, which was edited"
          end
        end
        begin
          UserMailer.nightly_user_activity(user, pages, works).deliver!
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message}"
        end
      end
    end
  end

end
