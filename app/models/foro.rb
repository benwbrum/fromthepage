class Foro < ActiveRecord::Base
 belongs_to :user
 belongs_to :element, polymorphic: true



end