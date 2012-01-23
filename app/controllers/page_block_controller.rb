class PageBlockController < AdminController
  def list
    @page_blocks = PageBlock.find(:all, {:order => "description"})
  end
  
  def edit
    @page_block = PageBlock.find(params[:page_block_id])
  end
  
  def update
    @page_block = PageBlock.find(params[:page_block][:id])
    @page_block.update_attributes(params[:page_block])   
    redirect_to :action=>'list'   
  end
  
  def new
    @page_block = PageBlock.new
    # populate tag, view and controller
    @page_block.controller = params[:origin_controller]
    @page_block.view = params[:origin_action]
    @page_block.tag = params[:tag]
    @page_block.description = @page_block.controller + "->" + @page_block.view + "->" + @page_block.tag = params[:tag] 
    @page_block.save!
    redirect_to :action => 'edit', :page_block_id => @page_block.id
  end

end
