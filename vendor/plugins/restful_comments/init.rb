#puts "BEGIN restful_comments init.rb"
require 'restful_comments_commentable'
require 'restful_comments_helper'

ActiveRecord::Base.send :include, RestfulComments::Commentable
ActionView::Base.send :include, RestfulComments::Helper

# my bit
#puts Comment.inspect

#puts "END restful_comments init.rb"
