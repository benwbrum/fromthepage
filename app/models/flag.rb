# == Schema Information
#
# Table name: flags
#
#  id                 :integer          not null, primary key
#  comment            :text(65535)
#  content_at         :datetime
#  provenance         :string(255)
#  snippet            :text(65535)
#  status             :string(255)      default("unconfirmed")
#  created_at         :datetime
#  updated_at         :datetime
#  article_version_id :integer
#  auditor_user_id    :integer
#  author_user_id     :integer
#  note_id            :integer
#  page_version_id    :integer
#  reporter_user_id   :integer
#
# Indexes
#
#  index_flags_on_article_version_id  (article_version_id)
#  index_flags_on_auditor_user_id     (auditor_user_id)
#  index_flags_on_author_user_id      (author_user_id)
#  index_flags_on_note_id             (note_id)
#  index_flags_on_page_version_id     (page_version_id)
#  index_flags_on_reporter_user_id    (reporter_user_id)
#
require 'flagger'

class Flag < ApplicationRecord
  belongs_to :author_user, class_name: 'User', optional: true
  belongs_to :page_version, optional: true
  belongs_to :article_version, optional: true
  belongs_to :note, optional: true
  belongs_to :reporter_user, class_name: 'User', optional: true
  belongs_to :auditor_user, class_name: 'User', optional: true

  module Status
    UNCONFIRMED = 'unconfirmed'
    CONFRIMED = 'spam'
    FALSE_POSITIVE = 'ham'
  end

  module Provenance
    USER_REPORTED = 'user'
    REGEX = 'regex'
  end

  def self.check_page(version)
    if version.user&.owner? || version.user&.account_type == 'Staff'
      return
    end
    if snippet = Flagger.check(version.transcription)
      flag = Flag.new
      flag.page_version = version
      flag.author_user = version.user
      flag.provenance = Provenance::REGEX
      flag.snippet = snippet
      flag.content_at = version.created_on
      flag.save!
    end
  end

  def self.check_article(version)
    if version.user&.owner? || version.user&.account_type == 'Staff'
      return
    end
    if snippet = Flagger.check(version.source_text)
      flag = Flag.new
      flag.article_version = version
      flag.author_user = version.user
      flag.provenance = Provenance::REGEX
      flag.snippet = snippet
      flag.content_at = version.created_on
      flag.save!
    end
  end

  def self.check_note(note)
    if note.user&.owner? || note.user.account_type == 'Staff'
      return
    end
    if snippet = Flagger.check(note.body)
      flag = Flag.new
      flag.note = note
      flag.author_user = note.user
      flag.provenance = Provenance::REGEX
      flag.snippet = snippet
      flag.content_at = note.created_at
      flag.save!
    end
  end

  def self.remove_owner_marked_content
    Flag.all.each do |flag|
      if flag.author_user !=nil && flag.author_user.owner? || (flag.author_user !=nil && flag.author_user.account_type == 'Staff')
        flag.delete
      end
    end
  end

  def ok_user
    user = self.author_user
    Flag.where(author_user: user).update_all({ auditor_user_id: Current.user.id, status: Status::FALSE_POSITIVE })
  end

  def mark_ok!
    self.auditor_user = Current.user
    self.status = Status::FALSE_POSITIVE
    self.save!
  end

  def revert_content!
    page_version.expunge if page_version
    article_version.expunge if article_version
    note.destroy if note

    self.auditor_user = Current.user
    self.status = Status::CONFRIMED
    self.save!
  end
end
