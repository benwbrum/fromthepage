class CommentsController < ApplicationController
	
	# GET /comments
	# GET /comments.xml
	def index
	    logger.debug("DEBUG in INDEX!")
		@comments = Comment.find(:all)
		
		respond_to do |format|
			format.html # index.rhtml
			format.xml  { render :xml => @comments.to_xml }
		end
	end
	
	# GET /comments/1
	# GET /comments/1.xml
	def show
		@comment = Comment.find( params[:id] )
		
		respond_to do |format|
			format.html { redirect_to @comment.commentable_path + '#' + 'comment_' + @comment.id.to_s }
			format.xml  { render :xml => @comment.to_xml }
		end
	end
	
	# GET /comments/1;edit
	# GET /comments/1.xml;edit
	def edit
		@comment = Comment.find( params[:id] )
		respond_to do |format|
#			format.html { render :partial => 'form_edit', :locals => { :comment => @comment } }
#			format.xml  { render :xml => @comment.to_xml }
			format.js
		end
	end
	
	# POST /comments
	# POST /comments.xml
	def create
	    logger.debug("DEBUG in #{__FILE__}")
		@comment = Comment.new( params[:comment] )
		@comment.user = current_user_get
		
		respond_to do |format|
    	    logger.debug("DEBUG format #{format.inspect}")
			if not @comment.commentable.class.comments_extension.can_comment?( @comment.commentable, @comment.parent, self.current_user_get )
        	    logger.debug("DEBUG A")
				flash[:notice] = 'You cann\'t create comment'
				format.html { redirect_to comment_url(@comment) }
				format.xml  { head :err }
				format.js	{ render :update do |page| page.alert "You cann't create this comment" end }
			elsif @comment.save
        	    logger.debug("DEBUG B1")
				format.js
        	    logger.debug("DEBUG B2")
			else
        	    logger.debug("DEBUG C")
				format.js
			end
		end
	end
	
	# PUT /comments/1
	# PUT /comments/1.xml
	def update
		@comment = Comment.find( params[:id] )		
		
		respond_to do |format|
			if not @comment.commentable.class.comments_extension.can_edit?( @comment.commentable, @comment, current_user_get )
				flash[:notice] = 'You cann\'t edit this comment'
				format.html { redirect_to comment_url(@comment) }
				format.xml  { head :err }
				format.js	{ render :update do |page| page.alert "You cann't edit this comment" end }
			elsif @comment.update_attributes(params[:comment])
				flash[:notice] = 'Comment was successfully updated.'
				format.html { redirect_to comment_url(@comment) }
				format.xml  { head :ok }
				format.js
			else
				format.html { render :action => "edit" }
				format.xml  { render :xml => @comment.errors.to_xml }
				format.js	
			end
		end
	end
	
	# DELETE /comments/1
	# DELETE /comments/1.xml
	def destroy
		@comment = Comment.find( params[:id] )
		
		if @comment.commentable.class.comments_extension.can_remove?( @comment.commentable, @comment, current_user_get )		
			@removed_ids = [ @comment.id ]
			
			for comment in @comment.descendants do
				@removed_ids << comment.id
			end
			
			@comment.destroy
			
			respond_to do |format|
#				format.html { redirect_to comments_url }
#				format.xml  { head :ok }
				format.js
			end
		else
			respond_to do |format|
#				format.html { redirect_to comments_url }
#				format.xml  { head :err }
				format.js	{ render :update do |page| page.alert "You can't remove this comment" end }
			end
		end
	end
	
	protected
	
	def current_user_get
		if not defined? current_user
			nil
		elsif current_user == :false
			nil
		else
			current_user
		end
	end
end
