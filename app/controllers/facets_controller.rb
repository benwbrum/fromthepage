class FacetsController < ApplicationController
  def enable
    @collection = Collection.find(params[:collection_id])
    @collection.facets_enabled = true
    @collection.save
    redirect_to edit_collection_path(@collection.owner, @collection)
  end

  def disable
    @collection = Collection.find(params[:collection_id])
    @collection.facets_enabled = false
    @collection.save
    redirect_to edit_collection_path(@collection.owner, @collection)
  end
end
