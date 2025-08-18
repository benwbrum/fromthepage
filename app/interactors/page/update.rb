class Page::Update < ApplicationInteractor
  attr_accessor :page, :collection, :work

  include Page::Lib::Common

  def initialize(page:, page_params:)
    @page        = page
    @page_params = page_params
    @collection  = @page.collection
    @work        = @page.work

    super
  end

  def perform
    ActiveRecord::Base.transaction do
      attributes = @page_params.to_h.except(:base_image)
      attributes['status'] = Page.statuses[:new] if @page_params[:status].blank?
      attributes['translation_status'] = Page.translation_statuses[:new] if @page_params[:translation_status].blank?
      @page.update_columns(attributes)

      @page.work.work_statistic&.recalculate

      process_uploaded_file(@page_params[:base_image]) if @page_params[:base_image]
    end
  end
end
