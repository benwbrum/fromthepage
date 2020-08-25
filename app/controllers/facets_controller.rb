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
    errors = []

    collection.metadata_coverages.each do |m|
      metadata = params[:metadata][m[:key]]
      m.facet_config.update(label: metadata['label'],
                            input_type: metadata['input_type'],
                            order: metadata['order'])

      if m.facet_config.errors.any?
        errors << m.facet_config.errors.full_messages.first
      end
    end

    if errors.empty?
      redirect_to collection_facets_path(collection.owner, collection), notice: "Collection facets updated successfully"
    else
      render('collection/facets', :locals => { :@metadata_coverages => collection.metadata_coverages, :@errors => errors })
    end
  end
end
