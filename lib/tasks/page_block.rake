namespace :page_block do
  desc "Updates PageBlock data"
  task update: :environment do
    update_login
    update_signup
  end

  def update_login
    p = PageBlock.where(controller: "account", view: "login").first
    p.controller = "sessions"
    p.view = "new"
    p.html = "<p>Welcome back to FromThePage!<p> If you don't have an account yet and wish to transcribe works, please <%= link_to \"sign up\", new_user_registration_path %>"
    p.save
    puts "Updated login page block."
  end

  def update_signup
    p = PageBlock.where(controller: "account", view: "signup").first
    p.controller = "registrations"
    p.view = "new"
    p.save
    puts "Updated signup page block."
  end
end
