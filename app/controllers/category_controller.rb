class CategoryController < ApplicationController
  enforce_permission_checks

  public :render_to_string
  protect_from_forgery

  # @collection is loaded from params[:collection_id] by ApplicationController. It can be a
  # Collection or a DocumentSet (which delegates #categories to its collection). Every action
  # looks its category up *through* @collection, so a category from another collection is a 404.

  def edit
    require_permission(:collection_owner, @collection)

    @category = @collection.categories.find(params[:category_id])
  end

  def update
    require_permission(:collection_owner, @collection)

    @category = @collection.categories.find(params[:category_id])
    if @category.update(category_params)
      flash[:notice] = t('.category_updated')
      ajax_redirect_to collection_subjects_path(@collection.owner, @collection, selected_category_id: @category.id)
    else
      render action: 'edit'
    end
  end

  def add_new
    require_permission(:collection_owner, @collection)

    @new_category = @collection.categories.new
    if params[:category_id].present?
      parent = @collection.categories.find(params[:category_id])
      @new_category.parent = parent
      @new_category.gis_enabled = parent.gis_enabled
      @new_category.bio_fields_enabled = parent.bio_fields_enabled
    end
  end

  def create
    require_permission(:collection_owner, @collection)

    @new_category = @collection.categories.new(category_params)
    parent_id = params.dig(:category, :parent_id)
    @new_category.parent = @collection.categories.find(parent_id) if parent_id.present?
    if @new_category.save
      flash[:notice] = t('.category_created')
      ajax_redirect_to collection_subjects_path(@collection.owner, @collection, selected_category_id: @new_category.id)
    else
      render action: 'add_new'
    end
  end

  def delete
    require_permission(:collection_owner, @collection)

    @category = @collection.categories.find(params[:category_id])
    @category.destroy

    flash[:notice] = t('.category_deleted')
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, selected_category_id: @category.parent_id)
  end

  def enable_bio_fields
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:bio_fields, true)
  end

  def disable_bio_fields
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:bio_fields, false)
  end

  def enable_gis
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:gis, true)
  end

  def disable_gis
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:gis, false)
  end

  def enable_org_fields
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:org_fields, true)
  end

  def disable_org_fields
    require_permission(:collection_owner, @collection)

    toggle_x_fields(:org_fields, false)
  end

  private

  # Callers check :collection_owner first.
  def toggle_x_fields(field, enable)
    @category = @collection.categories.find(params[:category_id])
    attribute = "#{field}_enabled".to_sym
    message = ".fields_#{enable ? 'enabled' : 'disabled'}_for"
    @category.update_attribute(attribute, enable)
    @category.descendants.each { |d| d.update_attribute(attribute, enable) }
    notice = t(".#{message}", title: @category.title)
    count = @category.descendants.count
    if count > 0
      notice << " and #{count} child " << 'category'.pluralize(count)
    end
    flash[:notice] = notice
    ajax_redirect_to collection_subjects_path(@collection.owner, @collection, selected_category_id: @category.id)
  end

  # collection_id and parent_id are never taken from params: the collection comes from
  # @collection, and create resolves the parent through it.
  def category_params
    params.require(:category).permit(:title, :bio_fields_enabled, :gis_enabled, :org_fields_enabled)
  end
end
