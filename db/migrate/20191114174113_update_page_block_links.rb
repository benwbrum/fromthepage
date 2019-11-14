class UpdatePageBlockLinks < ActiveRecord::Migration[5.2]
  def change
    pages = PageBlock.all
    pages.each do |page|
      if page.html&.include?("link_to('partly transcribed', :controller => 'demo')")
        page.html.gsub!("link_to('partly transcribed', :controller => 'demo')",
                        "link_to('partly transcribed', demo_path)")
        page.save
      elsif page.html&.include?("link_to(\"sign up\", \n                    { :controller => 'account',\n                      :action => 'signup', \n                      :ol => 'acct_login_sulnk' } )")
        page.html.gsub!("link_to(\"sign up\", \n                    { :controller => 'account',\n                      :action => 'signup', \n                      :ol => 'acct_login_sulnk' } )",
                        "link_to('sign up', new_user_registration_path)")
        page.save
      end
    end
  end
end
