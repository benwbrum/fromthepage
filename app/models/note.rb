class Note < ActiveRecord::Base
  attr_accessible :body
  # Notes are comments on pages.  In the future they may
  # be comments on works, comments on image fragments,
  # comments on articles, or questions and answers

  # automated stuff
  acts_as_tree

  # associations
  belongs_to :user
  belongs_to :page
  belongs_to :work
  belongs_to :collection
  has_one :deed

end
