class IaWork < ActiveRecord::Base
  belongs_to :user
  belongs_to :work
  has_many :ia_leaves
end
