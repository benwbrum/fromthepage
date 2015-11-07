class PageVersionController < ApplicationController

  before_filter :set_versions

  def set_versions
    @selected_version = @page_version.present? ? @page_version : @page.page_versions.first
    @previous_version = params[:compare_version_id] ? PageVersion.find(params[:compare_version_id]) : @selected_version.prev
  end

  def list
    render 'show'
  end


end