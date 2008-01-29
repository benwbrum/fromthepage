
module RestfulComments
  module Helper
    def restful_comments_include( options = {} )
      result = ''
      	
      if options && options[:stylesheet]
        result += stylesheet_link_tag options[:stylesheet].to_s
      elsif options && options[:style]
        result += stylesheet_link_tag 'style_' + options[:style].to_s, :plugin => 'restful_comments'
      else
        result += stylesheet_link_tag 'style_gray', :plugin => 'restful_comments'
      end
      		
      result += javascript_include_tag 'comments', :plugin => 'restful_comments'
      	
      return result
    end
    	
    def restful_comments_for( commentable )
      restful_annotations_for(commentable)
    end

    #######################
    # Comment hacks
    #######################
    def restful_annotations_for( commentable )
      render({:partial => 'comments/comments', 
              :locals => 
                { :commentable => commentable,
                  :comment_type => 'annotation' 
                }
              })
    end

    def restful_reviews_for( commentable )
      render({:partial => 'comments/comments', 
              :locals => 
                { :commentable => commentable,
                  :comment_type => 'review' 
                }
              })
    end
    
    
    
    
    
    ########################
    # Prototype hacks
    ########################
    def hack_form_remote_tag(options)
      tag = form_remote_tag(options)
      tag.sub('}); return false;', 
               ', onComplete: function(request) { eval(request.responseText); } }); return false;')
	end

	def hack_link_to_remote(label, options)
      tag = link_to_remote(label, options)
      tag.sub('}); return false;', 
               ', onComplete: function(request) { eval(request.responseText); } }); return false;')
	end



  end
end
