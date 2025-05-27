require 'fileutils'

class Database::Base < ApplicationInteractor
  RECORDS = {
    'users' => User,
    'collections' => Collection,
    'document_sets' => DocumentSet,
    'works' => Work,
    'pages' => Page,
    'page_versions' => PageVersion,
    'notes' => Note,
    'articles' => Article,
    'page_article_links' => PageArticleLink,
    'deeds' => Deed,
    'document_sets_works' => DocumentSetWork,
    'categories' => Category,
    'sc_collections' => ScCollection,
    'sc_manifests' => ScManifest,
    'sc_canvases' => ScCanvas,
    'transcription_fields' => TranscriptionField,
    'sections' => Section,
    'table_cells' => TableCell,
    'spreadsheet_columns' => SpreadsheetColumn,
    'editor_buttons' => EditorButton,
    'quality_samplings' => QualitySampling,
    'metadata_coverages' => MetadataCoverage,
    'facet_configs' => FacetConfig,
    'collection_blocks' => CollectionBlock,
    'collection_owners' => CollectionOwner,
    'collection_collaborators' => CollectionCollaborator,
    'collection_reviewers' => CollectionReviewer,
    'ahoy_activity_summaries' => AhoyActivitySummary,
    'ia_works' => IaWork,
    'ia_leaves' => IaLeaf,
    'work_statistics' => WorkStatistic,
    'transcribe_authorizations' => TranscribeAuthorization
  }.freeze

  RECORDS_WITH_ASSETS = {
    'collections' => 'public/uploads/collection/picture',
    'document_sets' => 'public/uploads/document_set/picture',
    'works' => 'public/uploads/work/picture',
    'pages' => 'public/images/working/upload',
    'users' => 'public/uploads/user/picture'
  }.freeze
end
