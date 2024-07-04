# == Schema Information
#
# Table name: collection_blocks
#
#  id            :bigint           not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  collection_id :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  fk_rails_c117458532                                   (user_id)
#  index_collection_blocks_on_collection_id_and_user_id  (collection_id,user_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (collection_id => collections.id)
#  fk_rails_...  (user_id => users.id)
#
class CollectionBlock < ApplicationRecord

  belongs_to :collection
  belongs_to :user

  validates :collection, presence: true
  validates :user, presence: true

end
