class Section < ActiveRecord::Base
  belongs_to :work, optional: true
  acts_as_list :scope => :work
  has_and_belongs_to_many :pages
  attr_accessible :title, :depth
  has_many :table_cells

end
