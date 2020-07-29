class FacetConfig < ApplicationRecord
  belongs_to :metadata_coverage
  after_commit :populate_facets

  def populate_facets
    works = self.metadata_coverage.collection.works

    works.each do |w|
      om = JSON.parse(w.original_metadata)

      unless w.work_facet
        w.create_work_facet
      end

      om.each do |o|
        unless o['label'].blank?
          if o['label'] == self['label']
            if self['input_type'] == "text"
              w.work_facet.update("s#{self['order']}".to_sym => self['label'])
            end
          end
        end
      end
    end
  end
end
