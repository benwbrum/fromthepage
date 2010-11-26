class PageBlockController < ApplicationController
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

end
