# A Deed is a scholarly contribution made by a user to a page. It's kind
# of like "doing a good deed." There are several types of deeds (which live in
# the DeedType model). Ex: "transcribed", "marked as blank"
class Deed < ActiveRecord::Base
  include RenderAnywhere

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
  
  before_save :calculate_prerender, :calculate_prerender_mailer

  def deed_type_name
    DeedType.name(self.deed_type)
  end

  def calculate_prerender
    self.prerender = render(:partial => 'deed/deed.html', :locals => { :deed => self, :long_view => false, :prerender => true  })
  end

  def calculate_prerender_mailer
    self.prerender_mailer = render(:partial => 'deed/deed', :locals => { :deed => self, :long_view => true, :prerender => true, :mailer => true })
  end
end
