class CategoryController < ApplicationController
  public :render_to_string
  protect_from_forgery

  def edit
  end

  def update
    if @category.update(category_params)
      flash[:notice] = t('.category_updated')
      ajax_redirect_to collection_subjects_path(@category.collection.owner, @category.collection)
    else
      render :action => 'edit'
    end
  end

  def add_new
    @new_category = Category.new
    if @collection.is_a?(DocumentSet)
      @new_category.collection = @collection.collection
    else
      @new_category.collection = @collection
    end
    if @category.present?
      @new_category.parent = @category
      @new_category.gis_enabled = @category.gis_enabled
      @new_category.bio_fields_enabled = @category.bio_fields_enabled
    end
  end

  def create
    @new_category = Category.new(category_params)
    @new_category.parent = Category.find(params[:category][:parent_id]) if params[:category][:parent_id].present?
    if @new_category.save
      flash[:notice] = t('.category_created')
      ajax_redirect_to collection_subjects_path(@new_category.collection.owner, @new_category.collection)
    else
      render :action => 'add_new'
    end
  end

  def delete
    anchor = @category.parent_id.present? ? "category-#{@category.parent_id}" : nil
    @category.destroy #_but_attach_children_to_parent

    flash[:notice] = t('.category_deleted')
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, {:anchor => anchor})
  end

  def enable_gis
    @category.update_attribute(:gis_enabled, true)
    @category.descendants.each {|d| d.update_attribute(:gis_enabled, true)}

    notice = t('.gis_enabled_for', title: @category.title)
    count = @category.descendants.count
    if count > 0
      notice << " and #{count} child " << "category".pluralize(count)
    end

    flash[:notice] = notice
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, {:anchor => "category-#{@category.id }"})
  end

  def disable_gis
    @category.update_attribute(:gis_enabled, false)
    @category.descendants.each {|d| d.update_attribute(:gis_enabled, false)}

    notice = t('.gis_disabled_for', title: @category.title)
    count = @category.descendants.count
    if count > 0
      notice << " and #{count} child " << "category".pluralize(count)
    end

    flash[:notice] = notice
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, {:anchor => "category-#{@category.id }"})
  end

  def enable_bio_fields
    @category.update_attribute(:bio_fields_enabled, true)
    @category.descendants.each {|d| d.update_attribute(:bio_fields_enabled, true)}

    notice = t('.bio_fields_enabled_for', title: @category.title)
    count = @category.descendants.count
    if count > 0
      notice << " and #{count} child " << "category".pluralize(count)
    end

    flash[:notice] = notice
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, {:anchor => "category-#{@category.id }"})
  end

  def disable_bio_fields
    @category.update_attribute(:bio_fields_enabled, false)
    @category.descendants.each {|d| d.update_attribute(:bio_fields_enabled, false)}

    notice = t('.bio_fields_disabled_for', title: @category.title)
    count = @category.descendants.count
    if count > 0
      notice << " and #{count} child " << "category".pluralize(count)
    end

    flash[:notice] = notice
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, {:anchor => "category-#{@category.id }"})
  end

  private

  def category_params
    params.require(:category).permit(:title, :bio_fields_enabled, :gis_enabled, :collection_id, :parent_id)
  end
end
