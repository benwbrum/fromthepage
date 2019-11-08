class PageBlock < ApplicationRecord
  attr_accessor :rendered_html
  attr_accessible :html
end
