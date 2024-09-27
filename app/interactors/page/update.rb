class Page::Update
  include Page::Lib::Common
  include Interactor

  def initialize(page:, page_params:)
    @page        = page
    @page_params = page_params

    super
  end

  def call
    ActiveRecord::Base.transaction do
      attributes = @page_params.to_h.except(:base_image)
      attributes['status'] = Page.statuses[:new] if @page_params[:status].blank?
      attributes['translation_status'] = Page.translation_statuses[:new] if @page_params[:translation_status].blank?
      @page.update_columns(attributes)

      @page.work.work_statistic&.recalculate

      process_uploaded_file(@page_params[:base_image]) if @page_params[:base_image]
    end

    context
  end
end
