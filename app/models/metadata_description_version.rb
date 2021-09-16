class MetadataDescriptionVersion < ApplicationRecord
  belongs_to :user
  belongs_to :work

  def display
    self.created_at.strftime("%b %d, %Y") + " - " + self.user.display_name + " (#{self.version_number})"
  end

end
