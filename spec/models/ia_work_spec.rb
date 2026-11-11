require 'spec_helper'

RSpec.describe IaWork, type: :model do
  describe 'description length' do
    it 'matches the maximum length accepted by Work' do
      ia_work_maximum = described_class.validators_on(:description).filter_map do |validator|
        validator.options[:maximum] if validator.is_a?(ActiveModel::Validations::LengthValidator)
      end
      work_maximum = Work.validators_on(:description).filter_map do |validator|
        validator.options[:maximum] if validator.is_a?(ActiveModel::Validations::LengthValidator)
      end

      expect(ia_work_maximum).to include(described_class::DESCRIPTION_MAX_LENGTH)
      expect(ia_work_maximum).to eq(work_maximum)
    end
  end
end
