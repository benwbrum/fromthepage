class Section < ApplicationRecord
  belongs_to :work, optional: true
  acts_as_list :scope => :work
  has_and_belongs_to_many :pages
  has_many :table_cells
end
