class SemanticContribution < Contribution
  acts_as_votable cacheable_strategy: :update_columns
  after_create :insert_semantic_register

  attr_accessible :schema_type
  attr_accessor :semantic_proxy

  def initialize(args = {})
    super(args)
  end

  def fetch_semantic_content()
    self.text = SemanticHelper.describeSemanticContributionEntity(self.slug, true) || self.text
  end

  def as_json(options={})
    if (self.semantic_proxy)
      fetch_semantic_content()
    end
    super
  end

  def insert_semantic_register()
    SemanticHelper.insert(self.text)
  end
end
