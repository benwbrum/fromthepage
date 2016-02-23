require 'image_helper'
require 'open-uri' # TODO: Move elsewhere

namespace :fromthepage do


  desc "Process TeX figures"
  task :process_tex_figures, [:page_id] => :environment do |t,args|
    page_id = args.page_id
    print "fetching page with ID=#{page_id}\n"
    page = Page.find page_id
    
    TexFigure.process_artifacts(page)
  end

end