class Collection < ActiveRecord::Base
  has_many :works #, :order => :position
  has_many :articles
  has_many :categories, :order => 'title'
  has_many :deeds, :order => 'created_at DESC'
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
end
