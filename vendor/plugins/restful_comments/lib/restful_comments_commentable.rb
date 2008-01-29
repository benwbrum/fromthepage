# RestfulComments
module RestfulComments
	module Commentable #:nodoc:
		
		class CommentsExtension
			def can_comment?( commentable, comment, user )
				true
			end
			
			def can_edit?( commentable, comment, user )
				true
			end
			
			def can_remove?( commentable, comment, user )
				true
			end
			
			def can_view_citations?( commentable, comment, user )
				defined? RestfulCitations
			end
		end
		
		def self.included(base)
			base.extend ClassMethods
		end
		
		module ClassMethods
			def acts_as_restful_commentable( options = {}, &extension )				
				
				has_many :comments, :as => :commentable, :dependent => :destroy
									
				include RestfulComments::Commentable::InstanceMethods
				extend  RestfulComments::Commentable::SingletonMethods
				
				# Initializing comments_extension attribute
				self.comments_extension = CommentsExtension.new
				
				# Extend comments_extension with &extension, if specified
				unless extension.nil?
					self.comments_extension.extend Module.new( &extension )
				end
			end
		end
		
		module SingletonMethods
			
			attr_accessor :comments_extension			
			
		end
		
		module InstanceMethods
			
			# Get last comments
			def last_comments( count )
				Comment.find( :all, :conditions => [ "commentable_id = ? AND commentable_type = ?", self.id, self.class.to_s ], :order => "created_at DESC", :limit => count )
			end
		end
	end
end