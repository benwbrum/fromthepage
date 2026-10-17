# A Deed is a scholarly contribution made by a user to a page. It's kind
# of like "doing a good deed." There are several types of deeds (which live in
# the DeedType model). Ex: "transcribed", "marked as blank"
# == Schema Information
#
# Table name: deeds
#
#  id               :integer          not null, primary key
#  deed_type        :string(10)
#  is_public        :boolean          default(TRUE)
#  prerender        :string(8191)
#  prerender_mailer :string(8191)
#  created_at       :datetime
#  updated_at       :datetime
#  article_id       :integer
#  collection_id    :integer
#  note_id          :integer
#  page_id          :integer
#  user_id          :integer
#  visit_id         :integer
#  work_id          :integer
#
# Indexes
#
#  index_deeds_on_article_id                                        (article_id)
#  index_deeds_on_collection_id_and_created_at                      (collection_id,created_at)
#  index_deeds_on_collection_id_and_deed_type_and_created_at        (collection_id,deed_type,created_at)
#  index_deeds_on_created_at_and_collection_id                      (created_at,collection_id)
#  index_deeds_on_note_id                                           (note_id)
#  index_deeds_on_page_id                                           (page_id)
#  index_deeds_on_user_id_and_created_at                            (user_id,created_at)
#  index_deeds_on_visit_id                                          (visit_id)
#  index_deeds_on_work_id_and_created_at                            (work_id,created_at)
#  index_deeds_on_work_id_and_deed_type_and_user_id_and_created_at  (work_id,deed_type,user_id,created_at)
#
class Deed < ApplicationRecord
  belongs_to :article, optional: true
  belongs_to :collection, optional: true
  belongs_to :note, optional: true
  belongs_to :page, optional: true
  belongs_to :user, optional: true
  belongs_to :work, optional: true

  validates_inclusion_of :deed_type, in: DeedType.all_types
  scope :order_by_recent_activity, -> { order(created_at: :desc) }
  scope :active, -> { joins(:user).where(users: { deleted: false }) }
  scope :past_day, -> { where('created_at >= ?', 1.day.ago) }

  visitable class_name: 'Visit' # ahoy integration

  before_save :calculate_public

  after_save :async_calculations

  def deed_type_name
    DeedType.name(self.deed_type)
  end

  def async_calculations
    Deed::CalculateJob.perform_later(
      deed_id: self.id,
      user_id: Current.user&.id
    )
  end

  def calculate_public
    if self.collection
      self.is_public = !self.collection.restricted
    else
      self.is_public = true # work_add might be called before the work has been added to a collection
    end

    true # don't fail validation when is_public==false!
  end
end
