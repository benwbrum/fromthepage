class FacetConfig < ApplicationRecord
  belongs_to :metadata_coverage
  after_commit :populate_facets, on: :update
  validates :order, numericality: true, allow_blank: true
  validates :order, inclusion: { in: 0..9, if: :type_text? }, allow_blank: true
  validates :order, inclusion: { in: 0..2, if: :type_date? }, allow_blank: true

  def populate_facets
    works = self.metadata_coverage.collection.works

    works.each do |w|
      unless w.original_metadata.nil?
        om = JSON.parse(w.original_metadata)

        unless w.work_facet
          w.create_work_facet
        end

        om.each do |o|
          label = o['label']
          value = o['value']


          if label == self.metadata_coverage.key
            input_type = self['input_type']

            case input_type
            when "text"
              unless self['order'].nil?
                w.work_facet.update("s#{self['order']}".to_sym => value)
              end
            when "date"
              unless self['order'].nil?
                w.work_facet.update("d#{self['order']}".to_sym => Date.today.strftime("%F"))
              end
            end
          end
        end
      end
    end
  end

  def type_text?
    self.input_type == "text"
  end

  def type_date?
    self.input_type == "date"
  end
end
