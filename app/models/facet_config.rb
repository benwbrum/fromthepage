# == Schema Information
#
# Table name: facet_configs
#
#  id                   :integer          not null, primary key
#  input_type           :string(255)
#  label                :string(255)
#  order                :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  metadata_coverage_id :integer          not null
#
# Indexes
#
#  index_facet_configs_on_metadata_coverage_id  (metadata_coverage_id)
#
# Foreign Keys
#
#  fk_rails_...  (metadata_coverage_id => metadata_coverages.id)
#
class FacetConfig < ApplicationRecord
  belongs_to :metadata_coverage
  validates :order, numericality: true, allow_blank: true
  validates :order, inclusion: { in: 0..9, if: :type_text? }, allow_blank: true
  validates :order, inclusion: { in: 0..2, if: :type_date? }, allow_blank: true


  def label_hash
    label_hash = JSON.parse(self.label)
  end

  def localized_label(locale)
    return nil if self.label.nil?

    locale_label = label_hash[locale.to_s]
    if locale_label
      locale_label
    else
      label_hash.first[1]
    end
  end

  # static method to recalculate all work facet values
  def self.populate_facets(collection)
    works = collection.works

    works.each do |w|
      update_work_facet(w, collection)
    end
  end

  # static method to recalculate the work_facet values for a work
  def self.update_work_facet(w, collection)
    unless w.original_metadata.nil?
      om = JSON.parse(w.original_metadata)

      w.work_facet.destroy! if w.work_facet
      w.create_work_facet

      new_attributes = {}
      collection.facet_configs.each do |facet|
        om.each do |o|
          label = o['label']
          value = o['value']


          if label == facet.metadata_coverage.key
            input_type = facet['input_type']

            case input_type
            when 'text'
              unless facet['order'].nil?
                if value.kind_of? Hash
                  value = value['value'] || value['@value']
                end
                value = Nokogiri::HTML(value).text
                new_attributes["s#{facet['order']}".to_sym] = value
              end
            when 'date'
              unless facet['order'].nil?
                begin
                  date = Date.edtf(value)
                  new_attributes["d#{facet['order']}".to_sym] = date
                rescue
                  logger.info("Tried to create a date facet from invalid date #{value}")
                end
              end
            end
          end
        end
      end
      w.work_facet.update(new_attributes)
    end
  end


  def self.update_facets(work)
    if work.collection.facets_enabled?
      update_work_facet(work, work.collection)
    end
  end

  def type_text?
    self.input_type == 'text'
  end

  def type_date?
    self.input_type == 'date'
  end
end
