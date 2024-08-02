class FacetsController < ApplicationController

  def enable
    @collection = Collection.find(params[:collection_id])
    @collection.facets_enabled = true
    @collection.save

    # create metadata_coverages for collections that don't have any.
    if @collection.metadata_coverages.empty?
      @collection.works.each do |w|
        next if w.original_metadata.nil?

        om = JSON.parse(w.original_metadata)

        om.each do |m|
          next if m['label'].blank?

          label = m['label']

          collection = w.collection

          next if w.collection.nil?

          mc = collection.metadata_coverages.build

          # check that record exist
          test = collection.metadata_coverages.where(key: label).first

          # increment count field if a record is returned
          if test
            test.count = test.count + 1
            test.save
          end

          next unless test.nil?

          mc.key = label.to_sym
          mc.save
          mc.create_facet_config(metadata_coverage_id: mc.collection_id)
        end
      end
    end

    redirect_to collection_facets_path(@collection.owner, @collection)
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
      unless metadata.nil?
        if metadata['order'].blank?
          facet_label = nil
        else
          facet_label = metadata['label'].presence || m.key
          if m.facet_config.label.nil?
            label_hash = {}
          else
            label_hash = JSON.parse(m.facet_config.label)
          end
          label_hash[locale.to_s] = facet_label
          facet_label = label_hash.to_json
        end

        m.facet_config.update(label: facet_label,
          input_type: metadata['input_type'],
          order: metadata['order'])
      end

      errors << m.facet_config.errors.full_messages.first if m.facet_config.errors.any?
    end

    if errors.empty?
      # renumber down to contiguous 0-indexed values
      collection.facet_configs.where(input_type: 'text').where.not(order: nil).each_with_index do |facet_config, i|
        facet_config.order = i
        facet_config.save!
      end
      collection.facet_configs.where(input_type: 'date').where.not(order: nil).each_with_index do |facet_config, i|
        facet_config.order = i
        facet_config.save!
      end
      FacetConfig.populate_facets(collection)

      redirect_to collection_facets_path(collection.owner, collection), notice: t('collection.facets.collection_facets_updated_successfully')
    else
      @metadata_coverages = collection.metadata_coverages
      @errors = errors

      render('collection/facets')
    end
  end

  def localize
    render('collection/localize', layout: false)
  end

  def update_localization
    facet_params = params[:facets]
    facet_params.each do |facet_config_id, labels|
      facet_config = @collection.facet_configs.where(id: facet_config_id).first
      if facet_config
        facet_config.label = labels.to_json
        facet_config.save!
      end
    end
    ajax_redirect_to collection_facets_path(@collection.owner, @collection)
  end

end
