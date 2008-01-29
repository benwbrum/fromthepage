class RestfulCommentsToVersion1 < ActiveRecord::Migration
  def self.up
    Rails.plugins["restful_comments"].migrate(1)
  end

  def self.down
    Rails.plugins["restful_comments"].migrate(0)
  end
end
