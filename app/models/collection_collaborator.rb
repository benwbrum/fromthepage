# == Schema Information
#
# Table name: collection_collaborators
#
#  collection_id :integer
#  user_id       :integer
#
class CollectionCollaborator < ApplicationRecord
  belongs_to :collection
  belongs_to :user
end
