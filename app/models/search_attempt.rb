class SearchAttempt < ApplicationRecord
    belongs_to :user, optional: true
    belongs_to :collection, optional: true
    belongs_to :work, optional: true
    visitable class_name: "Visit" # ahoy integration

    after_create :update_slug

    def to_param
        "#{query.parameterize}-#{id}"
    end

    def update_slug
        update_attribute(:slug, to_param)
    end
end
