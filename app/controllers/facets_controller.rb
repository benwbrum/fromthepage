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

  def update
    collection = Collection.find(params[:collection_id])

    collection.metadata_coverages.each do |m|
      metadata = params[:metadata][m[:key]]
      m.facet_config.label = metadata['label']
      m.facet_config.input_type = metadata['input_type']
      m.facet_config.order = metadata['order']
      m.facet_config.save
    end

    redirect_to collection_facets_path(collection.owner, collection), notice: "Collection facets updated successfully"
  end
end
