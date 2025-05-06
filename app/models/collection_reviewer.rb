# == Schema Information
#
# Table name: collection_reviewers
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer
#  user_id       :integer
#
# Indexes
#
#  index_collection_reviewers_on_collection_id  (collection_id)
#  index_collection_reviewers_on_user_id        (user_id)
#
class CollectionReviewer < ApplicationRecord
  belongs_to :collection
  belongs_to :user
end
