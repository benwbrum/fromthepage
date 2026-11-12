# Permission rules for Collection.
#
# Copied verbatim from the model predicates they replace. The originals stay in place,
# marked `TODO: Deprecate`, until every controller uses `require_permission`. Until then,
# a change to one must be made to the other.
module Permissions
  module CollectionRules
    module_function

    # User#like_owner? (Collection branch)
    def owner?(user, collection)
      return false unless user

      user == collection.owner || collection.owners.include?(user)
    end

    # User#collaborator? (Collection branch)
    def collaborator?(user, collection)
      return false unless user

      collection.collaborators.include?(user)
    end

    # Collection#show_to?
    def viewer?(user, collection)
      (!collection.restricted && collection.works.present? && collection.collection_blocks.where(user_id: user&.id).none?) ||
        owner?(user, collection) ||
        collaborator?(user, collection)
    end

    # User#can_review?. Accepts a Page (resolved to its work's collection) or a Collection.
    # A signed-out user can never review. The original is an instance method on User, so it
    # never saw a nil user.
    def reviewer?(user, record)
      return false unless user

      collection = record.is_a?(Page) ? record.work.collection : record

      if collection.review_type_restricted?
        collection.reviewers.include?(user) || owner?(user, collection)
      else
        true
      end
    end
  end
end
