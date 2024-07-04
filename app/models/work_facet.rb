# == Schema Information
#
# Table name: work_facets
#
#  id         :integer          not null, primary key
#  d0         :date
#  d1         :date
#  d2         :date
#  s0         :string(512)
#  s1         :string(512)
#  s2         :string(512)
#  s3         :string(512)
#  s4         :string(512)
#  s5         :string(512)
#  s6         :string(512)
#  s7         :string(512)
#  s8         :string(512)
#  s9         :string(512)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  work_id    :integer          not null
#
# Indexes
#
#  index_work_facets_on_work_id  (work_id)
#
# Foreign Keys
#
#  fk_rails_...  (work_id => works.id)
#
class WorkFacet < ApplicationRecord

  belongs_to :work

end
