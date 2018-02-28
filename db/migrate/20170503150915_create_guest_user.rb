class CreateGuestUser < ActiveRecord::Migration

#this functionality has been moved to a rake task
=begin  def change
    user = User.find_by(login: "guest_user")

    if !user
      password = Devise.friendly_token.first(8)
      guest_user = User.new
      guest_user.login = "guest_user"
      guest_user.email = "guest_user@fromthepage.com"
      guest_user.display_name = "Guest User"
      guest_user.password = password
      guest_user.password_confirmation = password
      guest_user.save!
    end
  end
=end
end
