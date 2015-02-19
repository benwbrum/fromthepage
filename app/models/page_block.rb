class PageBlock < ActiveRecord::Base
  attr_accessor :rendered_html
  attr_accessible :html
end
