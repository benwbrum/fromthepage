
Thredded::Messageboard.class_eval do
  clear_validators!

  validates :name,
            length: { within: Thredded.messageboard_name_length_range },
            presence: true
  validates :topics_count, numericality: true
  validates :position, presence: true, on: :update

end
