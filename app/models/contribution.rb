class Contribution < ActiveRecord::Base 
  extend FriendlyId
  friendly_id :slug_candidates, :use => [:slugged, :history]
  attr_accessible :text, :cached_weighted_score, :mark_id, :contribution_slug
  
  belongs_to :mark
  belongs_to :user
  
  validates :text, presence: true
  
  def initialize(args={})
    super(args)
  end
  
  def slug_candidates
    if self.slug
      [:slug]
    else
      [contribution_slug, :id]
    end
  end

  def better_than?(another_contribution)
    return self.id != another_contribution.id && self.cached_weighted_score > another_contribution.cached_weighted_score 
  end

  def prepare_for_show
  end
end
