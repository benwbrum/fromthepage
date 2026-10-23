class Page::Destroy < ApplicationInteractor
  attr_accessor :page

  def initialize(page:)
    @page = page

    super
  end

  def perform
    @page.destroy
  end
end
