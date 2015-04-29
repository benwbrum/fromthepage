class PageVersion < ActiveRecord::Base
  belongs_to :page
  belongs_to :user

  def prev
    page.page_versions.where("id < ?", id).first
  end

end