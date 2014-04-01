class NotesController < ApplicationController
#	
#	# GET /comments
#	# GET /comments.xml
#	def index
#		@comments = Comment.find(:all)
#		
#		respond_to do |format|
#			format.html # index.rhtml
#			format.xml  { render :xml => @comments.to_xml }
#		end
#	end
#	
#	# GET /comments/1
#	# GET /comments/1.xml
#	def show
#		@comment = Comment.find( params[:id] )
#		
#		respond_to do |format|
#			format.html { redirect_to @comment.commentable_path + '#' + 'comment_' + @comment.id.to_s }
#			format.xml  { render :xml => @comment.to_xml }
#		end
#	end
#	
#	# GET /comments/1;edit
#	# GET /comments/1.xml;edit
#	def edit
#		@comment = Comment.find( params[:id] )
#		respond_to do |format|
#			format.html { render :partial => 'form_edit', :locals => { :comment => @comment } }
#			format.xml  { render :xml => @comment.to_xml }
#			format.js
#		end
#	end
#	
#	# POST /comments
#	# POST /comments.xml
  def create
    @note = Note.new( params[:note] )
    # truncate the body for the title
    @note.title = @note.body
    # add param-loaded associations
    @note.page = @page
    @note.work = @work
    @note.collection = @collection

    @note.user = current_user

    respond_to do |format|
      if not user_signed_in?
	flash[:notice] = 'You must log in to create notes'
	format.html { render :text => "redirect_to comment_url(@comment)" }
	format.xml  { head :err }
	format.js	{ render :update do |page| page.alert "You must log in to create notes" end }
      elsif @note.save
	record_deed
	format.js
	format.html { redirect_to :back }
      else
	format.js
      end
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.deed.delete
    @note.delete
    flash[:notice] = "Deleted!"
    redirect_to :back
  end

  def edit
    @note = Note.find(params[:id])
  end

  def update
    @note = Note.find(params[:id])

    if @note.update_attributes(params[:note])
      flash[:success] = "Note successfully updated."
      redirect_to @note
    end
  end

  def show
    @note = Note.find(params[:id])
  end

  def record_deed
    deed = Deed.new
    deed.note = @note
    deed.page = @page
    deed.work = @work
    deed.collection = @collection
    deed.deed_type = Deed::NOTE_ADDED
    deed.user = current_user
    deed.save!
  end
end
