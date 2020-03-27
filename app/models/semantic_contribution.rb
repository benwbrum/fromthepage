class SemanticContribution < Contribution
  acts_as_votable cacheable_strategy: :update_columns
  
  attr_accessible :schema_type
  
  def initialize(args = {})
    super(args)
  end

end
