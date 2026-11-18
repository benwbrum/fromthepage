# Permission rules about the user themselves, or about a record's author (`user_id`).
# None of these have a model equivalent; the checks were inline in controllers.
module Permissions
  module UserRules
    module_function

    def signed_in?(user)
      user.present?
    end

    def admin?(user)
      !!user&.admin
    end

    # The account-level "owner" flag (can create collections), not ownership of a record.
    def owner_account?(user)
      !!user&.owner
    end

    def same_user?(user, other)
      user.present? && user == other
    end

    def author?(user, record)
      user.present? && record.user_id == user.id
    end
  end
end
