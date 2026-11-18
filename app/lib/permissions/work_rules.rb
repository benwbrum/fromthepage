# Permission rules for Work.
#
# Copied verbatim from the model predicates they replace. The originals stay in place,
# marked `TODO: Deprecate`, until every controller uses `require_permission`. Until then,
# a change to one must be made to the other.
module Permissions
  module WorkRules
    module_function

    # User#like_owner? (Work branch)
    def owner?(user, work)
      return false unless user

      if work.collection
        CollectionRules.owner?(user, work.collection)
      else
        user == work.owner
      end
    end

    # User#can_transcribe?. `collection` is the Collection or DocumentSet the work is being
    # accessed through, if known. A signed-out user can never transcribe. The original is an
    # instance method on User, so it never saw a nil user.
    def transcriber?(user, work, collection = nil)
      return false unless user
      return true if RecordRules.owner?(user, collection)

      collection ||= work.access_object(user) || work.collection

      return true if collection.is_a?(DocumentSet) && owner?(user, work)

      has_collection_access =
        collection.visibility_public? ||
        collection.collaborators.exists?(id: user.id) ||
        (collection.collection&.collaborators&.exists?(id: user.id) if collection.is_a?(DocumentSet))

      has_scribe_access = work&.scribes&.include?(user)

      return false unless has_collection_access || has_scribe_access

      !work&.restrict_scribes || has_scribe_access || owner?(user, work)
    end
  end
end
