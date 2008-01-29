#class RestfulCommentsHacks < ActiveRecord::Migration
#  def self.up
#    add_column :comments, :type, :string, :limit => 8, :default => 'comment'
#    add_column :comments, :status, :string, :limit => 8
#    
#  end
#
#  def self.down
#    remove_column :comments, :type
#    remove_column :comments, :status
#  end
#end
class RestfulCommentsHacks < ActiveRecord::Migration
  def self.up
    Rails.plugins["restful_comments"].migrate(2)
  end

  def self.down
    Rails.plugins["restful_comments"].migrate(1)
  end
end
