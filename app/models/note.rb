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
  after_save :update_page_last_note

  validates :body, presence: true

  scope :active, -> { joins(:user).where(users: {deleted: false}) }

  after_create :check_content

  def check_content
    Flag.check_note(self)
  end

  def email_users
    if SMTP_ENABLED
      if collection.metadata_only_entry?
        previous_users = User.joins(:notes).where(notes: {id: self.work.notes.ids}).joins(:notification).where(notifications: {note_added: true}).distinct
      else
        previous_users = User.joins(:notes).where(notes: {id: self.page.notes.ids}).joins(:notification).where(notifications: {note_added: true}).distinct
      end
      previous_users.each do |user|
        #send email regarding previous note, if it isn't the same user
        if (user.id != self.user_id && self.work.access_object(user))
          begin
            UserMailer.added_note(user, self).deliver!
          rescue StandardError => e
            print "SMTP Failed: Exception: #{e.message}"
          end
        end
      end
    end
  end

  def update_page_last_note
    self.page.update_column(:last_note_updated_at, page.notes.last.updated_at) if self.page
  end

end
