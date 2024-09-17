class Page::Create
  include Page::Lib::Common
  include Interactor

  def initialize(work:, page_params:)
    @work        = work
    @page_params = page_params

    super
  end

  def call
    ActiveRecord::Base.transaction do
      @page = Page.new(@page_params)
      @work.pages << @page

      context.page = @page
      process_uploaded_file(@page_params[:base_image]) if @page_params[:base_image]
    end

    context
  end
end
