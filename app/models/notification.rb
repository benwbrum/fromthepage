class Notification < ApplicationRecord
  belongs_to :user, optional: true
end
