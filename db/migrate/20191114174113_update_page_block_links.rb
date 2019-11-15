class UpdatePageBlockLinks < ActiveRecord::Migration[5.2]
  def change
    pages = PageBlock.all

    pages.each do |page|
      if page.html&.include?("partly transcribed")
        page.html.gsub!(/link_to\('partly transcribed'.+'\)/,
                        "link_to('partly transcribed', demo_path)")
        page.save
      elsif page.html&.include?("sign up")
        page.html.gsub!(/link_to\("sign up.+\)/m,
                        "link_to('sign up', new_user_registration_path)")
        page.save
      end
    end
  end
end
