class Page::Create < ApplicationInteractor
  attr_accessor :page

  include Page::Lib::Common

  def initialize(work:, page_params:)
    @work        = work
    @page_params = page_params

    super
  end

  def perform
    ActiveRecord::Base.transaction do
      @page = Page.new(@page_params)
      @work.pages << @page

      process_uploaded_file(@page_params[:base_image]) if @page_params[:base_image]
    end
  end
end
