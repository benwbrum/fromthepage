namespace :fromthepage do
  desc "nightly collection activity sent to users"
  task :nightly_user_activity => :environment do
    #find added works and get collection ids

    added_works = Work.joins(:deeds).where(deeds: {deed_type: 'work_add'}).merge(Deed.past_day).distinct
    col_ids = added_works.pluck(:collection_id)
    #get all users from collection
    works_users = User.joins(:deeds).where(deeds: {collection_id: col_ids}).joins(:notification).where(notifications: {work_added: true}).distinct
    #find edited pages
    page_ids = Page.joins(:deeds).where(deeds: {deed_type: ['page_edit', 'page_index', 'ocr_corr']}).merge(Deed.past_day).distinct.pluck(:id)
    #get users from edited pages
    page_users = User.joins(:deeds).where(deeds: {page_id: page_ids}).where(deeds: {deed_type: ['page_trans', 'page_edit', 'page_index', 'ocr_corr']}).joins(:notification).where(notifications: {page_edited: true}).distinct
    #combine user lists
    all_users = (works_users + page_users).uniq
    #for each user, get added works and edited pages then pass to mailer
    all_users.each do |user|
      if works_users.include?(user) && user.notification.work_added
        #find the collections this user has worked in
        ids = user.deeds.pluck(:collection_id).uniq
        #find which of the new works are in collections the user has contributed to but that the user hasn't uploaded themselves
        works = added_works.where.not(deeds: {user_id: user.id}).where(collection_id: ids)
        works.each do |work|
          puts "#{user.display_name} had #{work.title} added to #{work.collection.title}"
        end
      end
      if page_users.include?(user) && user.notification.page_edited
        pages = Page.where(id: page_ids).joins(:deeds).where(deeds: {user_id: user.id}).distinct
        pages.each do |page|
          puts "#{user.display_name} worked on edited page: #{page.title} in #{page.work.title}"
        end
      end
    end
  end

end
