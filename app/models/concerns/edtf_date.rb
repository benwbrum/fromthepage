# app/models/concerns/edtf_date.rb
module EdtfDate
  extend ActiveSupport::Concern

  class_methods do
    def edtf_date_attribute(*attributes)
      attributes.each do |attribute|
        define_method("#{attribute}=") do |date_as_edtf|
          if date_as_edtf.respond_to?(:to_edtf)
            self[attribute] = date_as_edtf.to_edtf
          else
            # the edtf-ruby gem has some gaps in coverage for e.g. seasons
            self[attribute] = date_as_edtf.to_s
          end
        end

        define_method(attribute) do
          raw_date = self[attribute]
          date = Date.edtf(raw_date)

          return nil if raw_date.nil?
          return raw_date if date.nil?

          date.edtf
        end

        validate do
          raw_date = self[attribute]
          next if raw_date.blank?

          errors.add(attribute, 'must be in EDTF format') if Date.edtf(raw_date).nil?
        end
      end
    end
  end
end
