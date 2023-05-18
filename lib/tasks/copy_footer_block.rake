namespace :copy_footer_block do
    desc "Copy the max length string of Users.collections.footer_block to User.footer_block"
    task copy: :environment do
      User.all.each do |user|
        max_length = 0
        max_footer_block = ""
        user.collections.each do |collection|
          if collection.footer_block && collection.footer_block.length > max_length
            max_length = collection.footer_block.length
            max_footer_block = collection.footer_block
          end
        end
        user.update_attribute(:footer_block, max_footer_block)
      end
    end
  end
  