class Collection < ActiveRecord::Base
  has_many :works, -> { order 'title' } #, :order => :position
  has_many :notes, -> { order 'created_at DESC' }
  has_many :articles
  has_many :categories, -> { order 'title' }
  has_many :deeds, -> { order 'created_at DESC' }
  belongs_to :owner, :class_name => 'User', :foreign_key => 'owner_user_id'
  has_and_belongs_to_many :owners, :class_name => 'User', :join_table => :collection_owners
  attr_accessible :title, :intro_block, :footer_block
end
