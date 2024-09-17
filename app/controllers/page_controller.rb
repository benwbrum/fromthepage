# handles administrative tasks for the page object
class PageController < ApplicationController
  require 'image_helper'
  include ImageHelper

  protect_from_forgery except: [:set_page_title]
  before_action :authorized?, except: [:alto_xml]

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, only: [:new, :create]

  def authorized?
    if user_signed_in?
      redirect_to dashboard_path if @work && !current_user.like_owner?(@work)
    else
      redirect_to dashboard_path
    end
  end

  def new
    @page = Page.new
    @page.title = @work.suggest_next_page_title
    @page.work = @work
  end

  def create
    result = Page::Create.call(work: @work, page_params: page_params)

    if result.success?
      subaction = params[:subaction]

      flash[:notice] = t('.page_created')
      if subaction == 'save_and_new'
        ajax_redirect_to({ controller: 'dashboard', action: 'startproject', anchor: 'create-work' })
      else
        ajax_redirect_to({ controller: 'work', action: 'pages_tab', work_id: @work.id, anchor: 'create-page' })
      end
    else
      @page = result.page

      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Edit route
  end

  def update
    result = Page::Update.call(page: @page, page_params: page_params)

    if request.xhr?
      render json: {
        success: result.success?,
        errors: result.errors
      }
    elsif result.success?
      flash[:notice] = t('.page_updated')
      redirect_to collection_edit_page_path(@collection.owner, @collection, @work, @page)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    result = Page::Destroy.call(page: @page)

    flash[:notice] = t('.page_deleted')
    redirect_to work_pages_tab_path(work_id: result.page.work_id)
  end

  def rotate
    result = Page::Rotate.call(page: @page, orientation: params[:orientation]&.to_i)

    redirect_back fallback_location: result.page
  end

  def reorder
    Page::Reorder.call(page: @page, direction: params[:direction])

    redirect_to work_pages_tab_path(work_id: @work.id)
  end

  def alto_xml
    # Transkribus ALTO does not include an ID on the String element, but we need one for Annotorious
    # we need to read the alto file and iterate over every string element, adding an ID attribute
    raw_alto = @page.alto_xml
    doc = Nokogiri::XML(raw_alto)

    doc.search('String').each_with_index do |string, i|
      string['ID'] = "string_#{i}"
    end

    render :plain => doc.to_xml, :layout => false, :content_type => 'text/xml'
  end

  private

  def page_params
    params.require(:page).permit(
      :page,
      :title,
      :base_image,
      :status,
      :translation_status
    )
  end

end
