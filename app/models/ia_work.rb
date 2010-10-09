class IaWork < ActiveRecord::Base
  belongs_to :user
  has_many :ia_leaves
end
