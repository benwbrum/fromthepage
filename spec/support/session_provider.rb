require "spec_helper"
include Capybara::DSL
include Capybara::RSpecMatchers

  class SessionProvider
    attr_reader :the_session
    def self.get_session
      the_session ||= create_session
    end

=begin
  login: utahdig
  display_name: utahdig
  print_name: Aaron
  email: u0498513@utah.edu
  owner: false
  admin: false
  crypted_password: 192b569a6d8ca481235a1d7c5daad2438ecb5938
  salt: ac18e500ca86341bb00fbc3c0f9e7b13c9d68520
  created_at: 2012-05-23 17:18:04.000000000 Z
  updated_at: 2013-01-31 22:21:20.000000000 Z
  remember_token: 
  remember_token_expires_at: 
  location: 
  website: 

=end

    private
    def self.create_session
      user = User.create(:login => "JoeJoeJoe",
                       # :email    => "alindeman@example.com",
                       :crypted_password => "192b569a6d8ca481235a1d7c5daad2438ecb5938",
                       :salt => "ac18e500ca86341bb00fbc3c0f9e7b13c9d68520")

      visit "/account/login"
      # puts "Here is method of visit: #{self.method(:visit).owner} "

      fill_in "Login",    :with => "JoeJoeJoe"
      fill_in "Password", :with => "password"
      click_button "Log in"
# Welcome back to FromThePage
      # unsuccessful:
      # Your login and password did not match. Feel free to contact alpha.info@fromthepage.com for help
      # page.should have_content("Recent Activity")
=begin
      puts "Page is a #{page.class}"
      puts "page.mode: #{page.mode} which is a #{page.mode.class}"
      puts "page.app: #{page.app.class}" 
      puts "page.app.methods: #{page.app.methods.sort} "
      puts "page.app.instance_variable_names: #{page.app.instance_variable_names}"
      puts "page.app.instance_variable_get(@mapping): #{page.app.instance_variable_get("@mapping")}"
=end
      return page
    end
  end
