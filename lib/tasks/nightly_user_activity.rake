namespace :fromthepage do
  desc "nightly collection activity sent to users"
  task :nightly_user_activity => :environment do
    #find added works and get collection ids

    added_works = Work.joins(:deeds).where(deeds: {deed_type: 'work_add'}).merge(Deed.past_day).distinct
    col_ids = added_works.pluck(:collection_id)
    #get all users from collection
    works_users = User.joins(:deeds).where(deeds: {collection_id: col_ids}).joins(:notification).where(notifications: {work_added: true}).distinct
    #find edited pages
    active_pages = Page.joins(:deeds).where(deeds: {deed_type: ['page_edit', 'ocr_corr', 'review']}).merge(Deed.past_day).distinct
    #find pages with notes
    note_pages = Page.joins(:deeds).where(deeds: {deed_type: 'note_add'}).merge(Deed.past_day).distinct
    #get users from edited pages
    page_users = User.joins(:deeds).where(deeds: {page_id: [active_pages.ids, note_pages.ids]}).where(deeds: {deed_type: ['page_trans', 'page_edit', 'review', 'note_add', 'ocr_corr']}).joins(:notification).where(notifications: {page_edited: true}).distinct
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
          user_page_ids = user.deeds.where(deeds: {deed_type: ['page_trans', 'page_edit', 'review', 'note_add', 'ocr_corr']}).pluck(:page_id).uniq
          #find pages that have been newly edited by someone other than the user (the user is not the last editor)
          pages = active_pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: ['page_trans', 'page_edit', 'review', 'ocr_corr']).last.user_id != user.id}
          #find pages that the user has worked on that has had notes added recently
          notes = note_pages.where(id: user_page_ids).select {|page| page if page.deeds.where(deed_type: 'note_add').last.user_id != user.id}
        end
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
        unless notes.nil?
          notes.each do |page|
            puts "#{user.display_name} has worked on page #{page.title} in collection #{page.collection.title}, which had a note added to it"
          end
        end
        begin
          UserMailer.nightly_user_activity(user, pages, works, notes).deliver!
        rescue StandardError => e
          print "SMTP Failed: Exception: #{e.message} \n"
        end
      end
    end
  end

end
