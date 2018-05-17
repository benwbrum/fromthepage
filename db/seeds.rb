# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)


#user : create a guest user
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