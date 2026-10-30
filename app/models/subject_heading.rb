class SubjectHeading < ApplicationRecord
  belongs_to :subject_heading_inventory

  def snapshot
    { 'heading' => heading, 'uri' => uri }
  end

  def selection_value
    snapshot.to_json
  end
end
