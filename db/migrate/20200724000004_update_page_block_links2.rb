class UpdatePageBlockLinks2 < ActiveRecord::Migration[5.0]
  def change
    pages = PageBlock.all
    pages.each do |page|
      page_changed = false
      unless page.html && page.html.match("link_to('partly transcribed', demo_path)")
        page.html&.gsub!(/link_to\('partly transcribed'.+'\)/,
                       "link_to('partly transcribed', demo_path)")
        page_changed = true
      end
      unless page.html && page.html.match("link_to('sign up', new_user_registration_path)")
        page.html&.gsub!(/link_to\("sign up.+\)/m,
                       "link_to('sign up', new_user_registration_path)")
        page_changed = true
      end
      if page_changed
        page.save
      end
    end
  end
end
