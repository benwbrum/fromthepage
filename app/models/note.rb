class Note < ApplicationRecord
  # Notes are comments on pages.  In the future they may
  # be comments on works, comments on image fragments,
  # comments on articles, or questions and answers

  # automated stuff
  acts_as_tree

  # associations
  belongs_to :user, optional: true
  belongs_to :page, optional: true
  belongs_to :work, optional: true
  belongs_to :collection, optional: true
  has_one :deed, :dependent => :destroy
  has_many :flags

  after_save :email_users

  validates :body, presence: true

  scope :active, -> { joins(:user).where(users: {deleted: false}) }

  after_create :check_content

  def check_content
    Flag.check_note(self)
  end

  def email_users
    if SMTP_ENABLED
      previous_users = User.joins(:notes).where(notes: {id: self.page.notes.ids}).joins(:notification).where(notifications: {note_added: true}).distinct
      previous_users.each do |user|
        #send email regarding previous note, if it isn't the same user
        if (user.id != self.user_id)
          begin
            UserMailer.added_note(user, self).deliver!
          rescue StandardError => e
            print "SMTP Failed: Exception: #{e.message}"
          end
        end
      end
    end
  end

end
