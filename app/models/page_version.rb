class PageVersion < ActiveRecord::Base
  belongs_to :page
  belongs_to :user

  def display
    self.created_on.strftime("%b %d, %Y")+ " "+self.user.display_name

  end
    

  def prev
    page.page_versions.where("id < ?", id).first
  end

end