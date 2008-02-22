class RestfulCommentsHacks < ActiveRecord::Migration
  def self.up
#   Rails.plugins["restful_comments"].migrate(2)
  end

  def self.down
#    Rails.plugins["restful_comments"].migrate(1)
  end
end
