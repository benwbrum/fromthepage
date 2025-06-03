# == Schema Information
#
# Table name: collection_tags
#
#  collection_id :integer
#  tag_id        :integer
#
class CollectionTag < ApplicationRecord
  belongs_to :collection
  belongs_to :tag
end
