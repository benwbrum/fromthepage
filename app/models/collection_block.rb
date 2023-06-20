class CollectionBlock < ApplicationRecord
    belongs_to :collection
    belongs_to :user
  
    validates :collection, presence: true
    validates :user, presence: true
end
