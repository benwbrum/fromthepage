# Dispatches a rule to the rules module for a record's type, so callers can ask
# "does this user own this thing?" without caring whether it's a Collection,
# DocumentSet or Work.
#
# A record type without a rules module (Page, Note, nil, ...) gets `false`, which matches
# User#like_owner? returning false for types it doesn't know.
module Permissions
  module RecordRules
    RULES_BY_TYPE = {
      'Collection' => 'Permissions::CollectionRules',
      'DocumentSet' => 'Permissions::DocumentSetRules',
      'Work' => 'Permissions::WorkRules'
    }.freeze

    module_function

    def for(record)
      RULES_BY_TYPE[record.class.name]&.constantize
    end

    def owner?(user, record)
      rules = self.for(record)
      return false unless rules.respond_to?(:owner?)

      rules.owner?(user, record)
    end

    def viewer?(user, record)
      rules = self.for(record)
      return false unless rules.respond_to?(:viewer?)

      rules.viewer?(user, record)
    end

    def collaborator?(user, record)
      rules = self.for(record)
      return false unless rules.respond_to?(:collaborator?)

      rules.collaborator?(user, record)
    end
  end
end
