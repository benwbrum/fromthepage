# A Deed is a scholarly contribution made by a user to a page. It's kind
# of like "doing a good deed." There are several types of deeds (which live in
# the DeedType model). Ex: "transcribed", "marked as blank"
class Deed < ApplicationRecord
  belongs_to :article, optional: true
  belongs_to :collection, optional: true
  belongs_to :note, optional: true
  belongs_to :page, optional: true 
  belongs_to :user, optional: true
  belongs_to :work, optional: true

  validates_inclusion_of :deed_type, in: DeedType.all_types
  scope :order_by_recent_activity, -> { order('created_at DESC') }
  scope :active, -> { joins(:user).where(users: {deleted: false}) }
  scope :past_day, -> {where('created_at >= ?', 1.day.ago)}

  visitable class_name: "Visit" # ahoy integration

  before_save :calculate_prerender, :calculate_prerender_mailer, :calculate_public


  def article
    real_article = super
    unless real_article
      if DeedType.article_types.include? self.deed_type 
        real_article = Article.new(:id => 0, :title => '[deleted]')
      end
    end
    real_article
  end

  def page
    real_page = super
    unless real_page
      if DeedType.page_types.include? self.deed_type
        real_page = Page.new(:id => 0, :title => '[deleted]')
      end
    end
    real_page
  end

  def work
    real_work = super
    unless real_work
      # page deeds also require a mock work
      if DeedType.page_types.include? self.deed_type
        real_work = Work.new(:id => 0, :title => '[deleted]')
      end
    end
    real_work
  end

  def deed_type_name
    DeedType.name(self.deed_type)
  end

  def calculate_public
    if self.collection
      self.is_public = !self.collection.restricted
    else
      self.is_public = true # work_add might be called before the work has been added to a collection
    end
    return true # don't fail validation when is_public==false!
  end

  def calculate_prerender
    unless self.deed_type == DeedType::COLLECTION_INACTIVE || self.deed_type == DeedType::COLLECTION_ACTIVE
      renderer = ApplicationController.renderer.new
      self.prerender = renderer.render(:partial => 'deed/deed.html', :locals => { :deed => self, :long_view => false, :prerender => true  })
    end
  end

  def calculate_prerender_mailer
    renderer = ApplicationController.renderer.new
    self.prerender_mailer = renderer.render(:partial => 'deed/deed', :locals => { :deed => self, :long_view => true, :prerender => true, :mailer => true })
  end
end
