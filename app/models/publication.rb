class Publication < ActiveRecord::Base
  acts_as_tree 
	# SI MISMO, USUARIO

  belongs_to :user
  belongs_to :foro
  
end