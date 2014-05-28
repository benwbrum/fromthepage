class DemoController < ApplicationController

  DEMO_WORK = 16

  def index
    next_page = next_untranscribed_page
    screen = ((next_page.position-1) / DisplayController::PAGES_PER_SCREEN) + 1
    redirect_to :controller => 'display', :action => 'read_work', :work_id => DEMO_WORK, :page => screen
  end


  def next_untranscribed_page
    work = Work.find DEMO_WORK
    work.pages.where("xml_text is null").first
  end

end
