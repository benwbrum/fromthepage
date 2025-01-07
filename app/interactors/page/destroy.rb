class Page::Destroy
  include Interactor

  def initialize(page:)
    @page = page

    super
  end

  def call
    @page.destroy

    context
  end
end
