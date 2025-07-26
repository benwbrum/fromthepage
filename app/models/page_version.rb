# == Schema Information
#
# Table name: page_versions
#
#  id                 :integer          not null, primary key
#  created_on         :datetime
#  page_version       :integer          default(0)
#  source_translation :text(65535)
#  status             :string(255)
#  title              :string(255)
#  transcription      :text(16777215)
#  work_version       :integer          default(0)
#  xml_transcription  :text(16777215)
#  xml_translation    :text(65535)
#  page_id            :integer
#  user_id            :integer
#
# Indexes
#
#  index_page_versions_on_page_id  (page_id)
#  index_page_versions_on_user_id  (user_id)
#
class PageVersion < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :user, optional: true
  has_many :flags

  after_create :check_content

  def check_content
    Flag.check_page(self) if content_changed?
  end

  def content_changed?
    previous_version = self.prev
    return true unless previous_version

    %i[title status transcription xml_transcription source_translation xml_translation].any? do |attribute|
      self[attribute] != previous_version[attribute]
    end
  end

  def check_content
    Flag.check_page(self)
  end

  def display
    self.created_on.strftime("%b %d, %Y") + " - " + self.user.display_name
  end

  def prev
    page.page_versions.where("id < ?", id).first
  end

  def next
    page.page_versions.where("id > ?", id).last
  end

  def current_version?
    self.id == page.page_versions.pluck(:id).max
  end

  def expunge
    # if we are we the current version
    if self.current_version?
      #   copy the previous version's contents into the page and save without callbacks
      previous_version = self.prev
      if previous_version
        page.update_columns(
          :title => previous_version.title,
          :source_text => previous_version.transcription,
          :xml_text => previous_version.xml_transcription,
          :source_translation => previous_version.source_translation,
          :xml_translation => previous_version.xml_translation
        )
        if previous_version.page_version == 0
          # reset the page and work status
          page.update_columns(:status => nil)
          page.update_work_stats
        end
      else
        # no previous version exists, reset the page to blank state
        page.update_columns(
          :title => nil,
          :source_text => nil,
          :xml_text => nil,
          :source_translation => nil,
          :xml_translation => nil,
          :status => nil
        )
        page.update_work_stats
      end
    else
      #   renumber subsequent versions
      this_version = self
      while next_version = this_version.next do
        next_version.page_version -= 1
        next_version.save!
        this_version = next_version
      end
    end
    self.destroy!
  end
end
