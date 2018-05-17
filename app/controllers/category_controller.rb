class CategoryController < ApplicationController
  public :render_to_string
  protect_from_forgery

  # no layout if xhr request
  layout Proc.new { |controller| controller.request.xhr? ? false : nil }, :only => [:edit, :add_new, :update, :create]

  def edit
  end

  def update
    if @category.update_attributes(params[:category])
      flash[:notice] = "Category has been updated"
      ajax_redirect_to "#{request.env['HTTP_REFERER']}#category-#{@category.id}"
    else
      render :action => 'edit'
    end
  end

  def add_new
    @new_category = Category.new({ :collection_id => @collection.id })
    if @category.present?
      @new_category.parent = @category 
      @new_category.gis_enabled = @category.gis_enabled
    end
  end

  def create
    @new_category = Category.new(params[:category])
    @new_category.parent = Category.find(params[:category][:parent_id]) if params[:category][:parent_id].present?
    if @new_category.save
      flash[:notice] = "Category has been created"
      ajax_redirect_to "#{request.env['HTTP_REFERER']}#category-#{@new_category.id}"
    else
      render :action => 'add_new'
    end
  end

  def delete
    anchor = @category.parent_id.present? ? "#category-#{@category.parent_id}" : nil
    @category.destroy #_but_attach_children_to_parent
    flash[:notice] = "Category has been deleted"
    redirect_to "#{request.env['HTTP_REFERER']}#{anchor}"
  end
  def enable_gis
    @category.update_attribute(:gis_enabled, true)
    flash[:notice] = "GIS Enabled for #{@category.title}"
    ajax_redirect_to "#{request.env['HTTP_REFERER']}#category-#{@category.id}"
  end
  def disable_gis
    @category.update_attribute(:gis_enabled, false)
    flash[:notice] = "GIS Disabled for #{@category.title}"
    ajax_redirect_to "#{request.env['HTTP_REFERER']}#category-#{@category.id}"
  end
end