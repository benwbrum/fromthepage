class Api::SearchController < Api::ApiController

  include ApplicationHelper

  def public_actions
    return [:login, :list_semantic_references]
  end

  def list_semantic_references
    params.permit(:filter)
    entities = SemanticHelper.listSemanticContributionsByEntity(params[:filter] || {})&.bindings || []
    entityIDs = entities.map{ |entity| entity.idNote&.value&.split('/').last }
    entityIDs = ['semantic-contribution-12', 'semantic-contribution-11']
    info = SemanticContribution.select(
        'collections.id AS `collectionId`','collections.title AS `collectionTitle`',
        'works.id AS `workId`','works.title AS `workTitle`',
        'pages.id AS `pageId`','pages.title AS `pageTitle`',
        'pages.base_image', 'count(*) AS `referencesAmount`'
    ).joins(mark: { page: { work: :collection } }).where('contributions.slug in (?)', entityIDs).group('pages.id')
    info = getSemanticReferencesData(info)
    response_data = { referenced_slugs: entityIDs, references: info }
    response_serialized_object response_data
  end

  private
    def getSemanticReferencesData(semanticReferencesData)
      semanticReferences = [] 
      for semanticReference in semanticReferencesData do
        semanticReferenceHash = semanticReference.attributes
        semanticReferenceHash[:thumbnail] = semanticReference.base_image.split('.').join('_thumb.')
        semanticReferenceHash[:thumbnail] = file_to_url(semanticReferenceHash[:thumbnail])
        semanticReferenceHash[:base_image] = file_to_url(semanticReference.base_image)
        semanticReferences.push(semanticReferenceHash)
      end
      return semanticReferences
    end
end