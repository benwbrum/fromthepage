# frozen_string_literal: true

class PagesController < ApplicationController
  # ...

  def mark_inactive
    page = Page.find(params[:id])
    page.mark_inactive
    redirect_to pages_path
  end
end