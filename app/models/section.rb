# == Schema Information
#
# Table name: sections
#
#  id         :integer          not null, primary key
#  depth      :integer
#  position   :integer
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#  work_id    :integer
#
# Indexes
#
#  index_sections_on_work_id  (work_id)
#
class Section < ApplicationRecord

  belongs_to :work, optional: true
  acts_as_list scope: :work
  has_and_belongs_to_many :pages
  has_many :table_cells

end
