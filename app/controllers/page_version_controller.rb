class PageVersionController < ApplicationController

  before_action :set_versions

  def set_versions
    @selected_version = @page_version.present? ? @page_version : @page.page_versions.first
    @previous_version = params[:compare_version_id] ? PageVersion.find(params[:compare_version_id]) : @selected_version.prev
  end

  def list
    render 'show'
  end

  def htr
    @alto_xml = @selected_version.page.alto_xml
    @ai_txt = @selected_version.page.ai_plaintext
    render 'htr'
  end

end
