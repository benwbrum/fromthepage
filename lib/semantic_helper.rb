require_relative 'semantic_clients/virtuoso-client'
require_relative 'semantic_clients/default-semantic-client'

class SemanticHelper

  @@semanticClient = nil

  #### Insert a new group of triplets ####
  def self.insert(data)
    semanticClient.insert(data)
  end
  
  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listSemanticContributions(data = {})
    semanticClient.listSemanticContributions(data)
  end
  
  ## Lists semantic contributions matching filters: type and propertyValue(if someone match) ##
  def self.listEntities(data = {})
    semanticClient.listEntities(data)
  end

  def self.describeEntity(id, useDefaultGraph = false)
    semanticClient.describeEntity(id, useDefaultGraph)
  end

  def self.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    semanticClient.describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph)
  end

  def self.semanticClient
    if (@@semanticClient == nil)
      @@semanticClient = createSemanticClient()
    end
    return @@semanticClient
  end

  def self.createSemanticClient
    case ENV['SEMANTIC_CONNECTOR']
      when 'virtuoso'
        return VirtuosoClient.new()
      else
        return DefaultSemanticClient.new()
    end
  end

end
