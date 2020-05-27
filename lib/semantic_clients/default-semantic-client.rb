class DefaultSemanticClient

  def insert(jsonld_string)
    return nil
  end

  def listSemanticContributions(filter = {})
    return []
  end

  def listEntities(filter)
    return []
  end

  def describeEntity(id, useDefaultGraph = false)
    return nil
  end

  def describeSemanticContributionEntity(idSemanticContribution, useDefaultGraph = false)
    return nil
  end

end
