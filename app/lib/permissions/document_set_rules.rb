# Permission rules for DocumentSet.
#
# Copied verbatim from the model predicates they replace. The originals stay in place,
# marked `TODO: Deprecate`, until every controller uses `require_permission`. Until then,
# a change to one must be made to the other.
module Permissions
  module DocumentSetRules
    module_function

    # User#like_owner? (DocumentSet branch)
    def owner?(user, document_set)
      return false unless user

      if document_set.collection
        CollectionRules.owner?(user, document_set.collection)
      else
        user == document_set.owner
      end
    end

    # User#collaborator? (DocumentSet branch)
    def collaborator?(user, document_set)
      return false unless user

      document_set.collection.collaborators.include?(user) || document_set.collaborators.include?(user)
    end

    # DocumentSet#show_to?
    def viewer?(user, document_set)
      document_set.is_public? ||
        document_set.visibility_read_only? ||
        owner?(user, document_set) ||
        collaborator?(user, document_set)
    end
  end
end
