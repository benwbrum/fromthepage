module DuplicateSlugCleanup
  extend ActiveSupport::Concern

  included do
    after_save :cleanup_duplicate_slug, if: -> { saved_change_to_slug? }
  end

  private

  def cleanup_duplicate_slug
    duplicates = FriendlyId::Slug
                   .where(slug: slug, sluggable_type: %w[Collection DocumentSet])
                   .where.not(sluggable_type: self.class.name, sluggable_id: id)

    duplicates.each do |dup|
      obj = dup.sluggable
      next unless obj.respond_to?(:owner_user_id)
      next unless obj.owner_user_id == owner_user_id
      next if obj.slug == slug
      dup.destroy if obj.slugs.count > 1
    end
  end
end
