class PageVersion < ApplicationRecord
  belongs_to :page, optional: true
  belongs_to :user, optional: true
  has_many :flags

  after_create :check_content

    def check_content
    if content_changed?
      Flag.check_page(self)
    end
  end

  def content_changed?
    previous_version = self.prev
    return true unless previous_version

    %i[title transcription xml_transcription source_translation xml_translation].any? do |attribute|
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
