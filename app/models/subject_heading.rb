class SubjectHeading < ApplicationRecord
  belongs_to :subject_heading_inventory

  # What AI drafts store for a suggested heading (see AiWorkMetadata#subject_heading_candidates)
  def snapshot
    { 'heading' => heading, 'uri' => uri }
  end
end
