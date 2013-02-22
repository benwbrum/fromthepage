class IaLeaf < ActiveRecord::Base
   self.table_name = "ia_leaves"
  belongs_to :ia_work
  belongs_to :page
end
