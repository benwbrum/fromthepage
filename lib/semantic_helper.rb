# require 'semantic_clients/virtuoso-client'
require_relative 'semantic_clients/virtuoso-client'

class SemanticHelper

  @@virtuosoClient = VirtuosoClient.new()

  #### Insert a new group of triplets ####
  def self.insert(data)
    @@virtuosoClient.insert(data)
  end
  
  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listSemanticContributions(data = {})
    @@virtuosoClient.listSemanticContributions(data)
  end
  
  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listEntities(data = {})
    @@virtuosoClient.listEntities(data)
  end

  def self.describeEntity(id, useDefaultGraph = false)
    @@virtuosoClient.describeEntity(id, useDefaultGraph)
  end

  def self.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    @@virtuosoClient.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph)
  end
end
