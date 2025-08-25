class Database::Export::DumpBuilder < Database::Base
  def initialize(collection_slugs: [], path: '')
    @collection_slugs = collection_slugs
    @path = path

    super
  end

  def perform
    RECORDS.each_key do |record_name|
      export_dump(send(record_name), record_name)
    end

    RECORDS_WITH_ASSETS.each_key do |record_name|
      handle_assets(record_name)
    end
  end

  private

  def export_dump(records, table_name)
    File.write(
      "#{@path}/#{table_name}.yml",
      records.map do |record|
        record.class.column_names.index_with do |column_name|
          record.read_attribute_before_type_cast(column_name)
        end
      end.to_yaml
    )
  end

  def collections
    @collections ||= Collection.where(slug: @collection_slugs)
  end

  def works
    @works ||= Work.where(collection_id: collections.select(:id))
  end

  def pages
    @pages ||= Page.where(work_id: works.select(:id))
  end

  def page_versions
    @page_versions ||= PageVersion.where(page_id: pages.select(:id))
  end

  def notes
    @notes ||= Note.where(collection_id: collections.select(:id))
                   .or(Note.where(work_id: works.select(:id)))
                   .or(Note.where(page_id: pages.select(:id)))
                   .distinct
  end

  def articles
    @articles ||= Article.where(collection_id: collections.select(:id))
  end

  def page_article_links
    @page_article_links ||= PageArticleLink.where(article_id: articles.select(:id))
  end

  def deeds
    @deeds ||= Deed.where(collection_id: collections.select(:id))
                   .or(Deed.where(work_id: works.select(:id)))
                   .or(Deed.where(page_id: pages.select(:id)))
                   .or(Deed.where(note_id: notes.select(:id)))
                   .or(Deed.where(article_id: articles.select(:id)))
                   .distinct
  end

  def document_sets
    @document_sets ||= DocumentSet.where(collection_id: collections.select(:id))
  end

  def document_sets_works
    @document_sets_works ||= DocumentSetWork.where(document_set_id: document_sets.select(:id))
  end

  def categories
    @categories ||= Category.where(collection_id: collections.select(:id))
  end

  def articles_categories
    @articles_categories ||= ArticlesCategory.where(article_id: articles.select(:id))
  end

  def sc_collections
    @sc_collections ||= ScCollection.where(collection_id: collections.select(:id))
  end

  def sc_manifests
    @sc_manifests ||= ScManifest.where(collection_id: collections.select(:id))
                                .or(ScManifest.where(work_id: works.select(:id)))
                                .or(ScManifest.where(sc_collection_id: sc_collections.select(:id)))
                                .distinct
  end

  def sc_canvases
    @sc_canvases ||= ScCanvas.where(page_id: pages.select(:id))
                             .or(ScCanvas.where(sc_manifest_id: sc_manifests.select(:id)))
  end

  def transcription_fields
    @transcription_fields ||= TranscriptionField.where(collection_id: collections.select(:id))
  end

  def sections
    @sections ||= Section.where(work_id: works.select(:id))
  end

  def table_cells
    @table_cells ||= TableCell.where(transcription_field_id: transcription_fields.select(:id))
                              .or(TableCell.where(work_id: works.select(:id)))
                              .or(TableCell.where(page_id: pages.select(:id)))
                              .or(TableCell.where(section_id: sections.select(:id)))
                              .distinct
  end

  def spreadsheet_columns
    @spreadsheet_columns ||= SpreadsheetColumn.where(transcription_field_id: transcription_fields.select(:id))
  end

  def editor_buttons
    @editor_buttons ||= EditorButton.where(collection_id: collections.select(:id))
  end

  def quality_samplings
    @quality_samplings ||= QualitySampling.where(collection_id: collections.select(:id))
  end

  def metadata_coverages
    @metadata_coverages ||= MetadataCoverage.where(collection_id: collections.select(:id))
  end

  def facet_configs
    @facet_configs ||= FacetConfig.where(metadata_coverage_id: metadata_coverages.select(:id))
  end

  def collection_blocks
    @collection_blocks ||= CollectionBlock.where(collection_id: collections.select(:id))
  end

  def collection_owners
    @collection_owners ||= CollectionOwner.where(collection_id: collections.select(:id))
  end

  def collection_collaborators
    @collection_collaborators ||= CollectionCollaborator.where(collection_id: collections.select(:id))
  end

  def collection_reviewers
    @collection_reviewers ||= CollectionReviewer.where(collection_id: collections.select(:id))
  end

  def ahoy_activity_summaries
    @ahoy_activity_summaries ||= AhoyActivitySummary.where(collection_id: collections.select(:id))
  end

  def ia_works
    @ia_works ||= IaWork.where(work_id: works.select(:id))
  end

  def ia_leaves
    @ia_leaves ||= IaLeaf.where(ia_work_id: ia_works.select(:id))
                         .or(IaLeaf.where(page_id: pages.select(:id)))
                         .distinct
  end

  def work_statistics
    @work_statistics ||= WorkStatistic.where(work_id: works.select(:id))
  end

  def transcribe_authorizations
    @transcribe_authorizations ||= TranscribeAuthorization.where(work_id: works.select(:id))
  end

  def thredded_messageboards
    @thredded_messageboards ||= Thredded::Messageboard.where(
      messageboard_group_id: thredded_messageboard_groups.select(:id)
    )
  end

  def thredded_messageboard_groups
    @thredded_messageboard_groups ||= Thredded::MessageboardGroup.where(
      id: collections.select(:thredded_messageboard_group_id)
    )
  end

  def users
    return @users if defined?(@users)

    direct_owners = User.where(id: collections.select(:owner_user_id))
    owners = User.where(id: collection_owners.select(:user_id))
    collaborators = User.where(id: collection_collaborators.select(:user_id))
    reviewers = User.where(id: collection_reviewers.select(:user_id))
    blocked = User.where(id: collection_blocks.select(:user_id))
    scribes = User.where(id: transcribe_authorizations.select(:user_id))
    deed_users = User.where(id: deeds.select(:user_id))

    @users = direct_owners.or(owners)
                          .or(collaborators)
                          .or(reviewers)
                          .or(blocked)
                          .or(scribes)
                          .or(deed_users)
                          .distinct

    @users
  end

  def handle_assets(record_name)
    if record_name == 'pages'
      handle_pages_assets
    else
      handle_picture_assets(record_name)
    end
  end

  def handle_picture_assets(record_name)
    assets_path = Rails.root.join(@path, RECORDS_WITH_ASSETS[record_name])
    FileUtils.mkdir_p(assets_path)

    send(record_name).each do |record|
      new_path = Rails.root.join(assets_path, record.id.to_s)
      FileUtils.mkdir_p(new_path)

      picture_url = record.picture_url&.delete_prefix('/')
      picture_path = File.join(Rails.root.join('public', picture_url || ''))

      scaled_url = record.picture_url(:scaled)&.delete_prefix('/')
      scaled_path = File.join(Rails.root.join('public', scaled_url || ''))

      thumb_url = record.picture_url(:thumb)&.delete_prefix('/')
      thumb_path = File.join(Rails.root.join('public', thumb_url || ''))

      [ picture_path, scaled_path, thumb_path ].each do |file|
        FileUtils.cp(file, new_path) if File.file?(file)
      end
    end
  end

  def handle_pages_assets
    assets_path = Rails.root.join(@path, RECORDS_WITH_ASSETS['pages'])
    FileUtils.mkdir_p(assets_path)

    pages.each do |page|
      picture_url = page.base_image&.sub(/.*public/, '')&.delete_prefix('/')
      picture_path = File.join(Rails.root.join('public', picture_url || ''))

      thumb_url = picture_url&.gsub('.jpg', '_thumb.jpg')
      thumb_path = File.join(Rails.root.join('public', thumb_url || ''))

      [ picture_path, thumb_path ].each do |file|
        FileUtils.cp(file, assets_path) if File.file?(file)
      end
    end
  end
end
