class Collection::Lib::ResolveSlugConflictsHandler
  def initialize(collection:)
    @collection = collection
    @slug = collection.slug
  end

  def perform
    return unless @collection.will_save_change_to_slug?
    return if @slug.blank?

    # NOTE: If there are active conflicts
    # we will let FriendlyId handle slug uniquify logic
    return if active_conflict?

    old_conflict_slugs.find_each do |friendly_slug|
      friendly_slug.slug = "#{friendly_slug.slug}-reclaimed-#{SecureRandom.hex(4)}"
      friendly_slug.save!(validate: false)
    end
  end

  private

  def owner
    @owner ||= @collection.owner
  end

  def active_conflict?
    owner.collections.where(slug: @slug).exists? || owner.document_sets.where(slug: @slug).exists?
  end

  def old_conflict_slugs
    return @old_conflict_slugs if defined?(@old_conflict_slugs)

    current_collection_ids = Collection.where(slug: @slug).select(:id)
    current_document_set_ids = DocumentSet.where(slug: @slug).select(:id)

    collection_slugs = FriendlyId::Slug
      .where(slug: @slug, sluggable_type: 'Collection')
      .where.not(sluggable_id: current_collection_ids)

    document_set_slugs = FriendlyId::Slug
      .where(slug: @slug, sluggable_type: 'DocumentSet')
      .where.not(sluggable_id: current_document_set_ids)

    @old_conflict_slugs = collection_slugs.or(document_set_slugs)

    @old_conflict_slugs
  end
end
