class Collection < ActiveRecord::Base
  has_many :works #, :order => :position
  has_many :articles
  has_many :categories, :order => 'title'
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
end
