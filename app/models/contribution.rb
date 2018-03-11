class Contribution < ActiveRecord::Base
  attr_accessible :text, :cached_weighted_score, :mark_id
  
  belongs_to :mark
  belongs_to :user
  
  validates :text, presence: true
  
  def initialize(args={})
    super(args)
  end
  
  def better_than?(another_contribution)
    return self.id != another_contribution.id && self.cached_weighted_score > another_contribution.cached_weighted_score 
  end
end
