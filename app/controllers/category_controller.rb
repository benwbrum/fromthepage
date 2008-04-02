class CategoryController < ApplicationController
  public :render_to_string
  def expand_category
    @article_partial = params[:article_partial]
    render :layout => false, :locals => { :article_partial => @article_partial }
  end
  def expand_article
    @article_partial = params[:article_partial]
    render :layout => false
  end


  def create
    category = Category.new(params[:category])
    category.save!
    redirect_to :action => 'manage', :collection_id => @collection.id
  end

  def delete
    @category.destroy #_but_attach_children_to_parent
    redirect_to :action => 'manage', :collection_id => @collection.id
  end
  
  def manage
    @category = Category.new({ :collection_id => @collection.id })
  end

  def add_child
    @category.children.create(:collection_id => @collection.id,
                              :title => params[:title])
    redirect_to :action => 'manage', :collection_id => @collection.id
  end

end
