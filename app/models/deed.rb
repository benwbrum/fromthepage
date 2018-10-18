class Deed < ActiveRecord::Base
  belongs_to :article
  belongs_to :collection
  belongs_to :note
  belongs_to :page
  belongs_to :user
  belongs_to :work

  validates_inclusion_of :deed_type, in: DeedType.all_types
  scope :order_by_recent_activity, -> { order('created_at DESC') }
  scope :active, -> { joins(:user).where(users: {deleted: false}) }
  scope :past_day, -> {where('created_at >= ?', 1.day.ago)}

  visitable # ahoy integration

  def deed_type_name
    DeedType.name(self.deed_type)
  end
end
