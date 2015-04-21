class PageVersionController < ApplicationController

  before_filter :set_versions

  def set_versions
    @version_current = @page
    @version_compare = @page_version.present? ? @page_version : @page.page_versions.first
  end

  def list
    render 'show'
  end

end