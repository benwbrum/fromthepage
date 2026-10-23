# spec/models/concerns/edtf_date_spec.rb
require 'spec_helper'

RSpec.describe EdtfDate, type: :model do
  # temporary model to test the concern in isolation
  with_model :TestModel do
    table do |t|
      t.string :sample_date
    end

    model do
      include EdtfDate
      edtf_date_attribute :sample_date
    end
  end

  let(:model) { TestModel.new }

  describe "getter method" do
    context "with a valid EDTF date" do
      it "returns an EDTF string" do
        model.sample_date = '2023-03'
        expect(model.sample_date).to eq('2023-03')
      end

      it "handles year-only precision" do
        model.sample_date = '2023'
        expect(model.sample_date).to eq('2023')
      end

      it "returns nil if date is not set" do
        expect(model.sample_date).to be_nil
      end
    end

    context "with an invalid EDTF date" do
      it "returns the original string if EDTF parsing fails" do
        model.sample_date = 'invalid-date'
        expect(model.sample_date).to eq('invalid-date')
      end
    end
  end

  describe "setter method" do
    it "stores EDTF date from an EDTF object" do
      edtf_date = Date.edtf('2023-03-27')
      model.sample_date = edtf_date
      expect(model[:sample_date]).to eq(edtf_date.to_edtf)
    end

    it "stores EDTF date from a string directly" do
      model.sample_date = '2023-03'
      expect(model[:sample_date]).to eq('2023-03')
    end

    it "handles edge cases where EDTF coverage is limited" do
      # example: season dates (unsupported by some EDTF gems)
      model.sample_date = '2023-21'
      expect(model[:sample_date]).to eq('2023-21')
    end
  end

  describe "validation" do
    it "passes validation for valid EDTF dates" do
      model.sample_date = '2023-12-31'
      expect(model).to be_valid
    end

    it "fails validation for invalid EDTF dates" do
      model.sample_date = 'not-edtf'
      expect(model).not_to be_valid
      expect(model.errors[:sample_date]).to include("must be in EDTF format")
    end

    it "passes validation if the date is nil or blank" do
      model.sample_date = ''
      expect(model).to be_valid

      model.sample_date = nil
      expect(model).to be_valid
    end
  end
end
