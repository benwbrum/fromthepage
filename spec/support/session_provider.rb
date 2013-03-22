require "spec_helper"
include Capybara::DSL
include Capybara::RSpecMatchers

  class SessionProvider
    attr_reader :the_session
    def self.get_session
      the_session ||= create_session
    end


    private
    def self.create_session

      user = FactoryGirl.create(:user)

      visit "/account/login"


      fill_in "Login",    :with => "joejoejoe"
      fill_in "Password", :with => "password"
      click_button "Log in"

      return page
    end
  end
