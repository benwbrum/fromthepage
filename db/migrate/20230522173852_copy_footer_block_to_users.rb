class CopyFooterBlockToUsers < ActiveRecord::Migration[6.0]
  def change
    User.find_each do |user|
      max_length = 0
      max_footer_block = ""
      user.collections.each do |collection|
        if collection.footer_block && collection.footer_block.length > max_length
          max_length = collection.footer_block.length
          max_footer_block = collection.footer_block
        end
      end
      user.update(footer_block: max_footer_block)
    end
  end
end
