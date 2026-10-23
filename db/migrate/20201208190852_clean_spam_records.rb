class CleanSpamRecords < ActiveRecord::Migration[6.0]
  def change
    Flag.remove_owner_marked_content
  end
end
