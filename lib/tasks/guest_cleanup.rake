namespace :fromthepage do

  desc "Remove guest accounts more than a week old" 
  task :guest_cleanup, [:days] => :environment do |t,args|

    num = args.days.to_i

    #permanent "Guest User" to migrate orphaned data
    @guest_user = User.find_by(login: "guest_user")
    
    if !@guest_user
      password = Devise.friendly_token.first(8)
      guest_user = User.new
      guest_user.login = "guest_user"
      guest_user.email = "guest_user@fromthepage.com"
      guest_user.display_name = "Guest User"
      guest_user.password = password
      guest_user.password_confirmation = password
      guest_user.save!
      notification = Notification.find_by(user_id: guest_user.id)
      notification.update(work_added: false, add_as_owner: false, add_as_collaborator: false, page_edited: false, note_added: false)
      @guest_user = guest_user
    end

    #find all guest users that are over a week old
    guests = User.where("guest = ? AND created_at < ?", true, num.days.ago)
    #for each user, find associated items and migrate to "Guest User"
    guests.each do |guest|

      deeds = Deed.where(user_id: guest.id)
      deeds.each do |d|
        d.user_id = @guest_user.id
        d.save!
      end

      page_versions = PageVersion.where(user_id: guest.id)
      page_versions.each do |p|
        p.user_id = @guest_user.id
        p.save!
      end
      article_versions = ArticleVersion.where(user_id: guest.id)
      article_versions.each do |a|
        a.user_id = @guest_user.id
        a.save!
      end

      notes = Note.where(user_id: guest.id)
      notes.each do |n|
        n.user_id = @guest_user.id
        n.save!
      end

      #double-check that the above was successful, then delete the user
      if guest.deeds.empty? && guest.page_versions.empty? && guest.article_versions.empty? && guest.notes.empty? &&
        #destroy the accounts after migrating the data
        guest.destroy
      else
        logger.debug("DEBUG Failed to delete user id #{guest.id}.")
      end

    end
  end
end
