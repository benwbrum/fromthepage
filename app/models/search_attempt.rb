class SearchAttempt < ApplicationRecord
    belongs_to :user, optional: true
    visitable class_name: "Visit" # ahoy integration
end
