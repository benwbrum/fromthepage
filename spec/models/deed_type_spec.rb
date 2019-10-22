require 'spec_helper'

RSpec.describe DeedType, type: :model do
  types_count = 16

  describe 'TYPES' do
    it "has all #{types_count} DeedTypes" do
      expect(DeedType::TYPES.length).to eq(types_count)
    end
  end

  describe '.all_types' do
    it 'returns the machine-readable types' do
      type = DeedType::PAGE_TRANSCRIPTION
      expect(DeedType.all_types).to include(type)
    end

    it 'does not return the full pair machine-readable and human-readable names' do
      pair = DeedType::TYPES.first
      expect(DeedType.all_types).to_not include(pair)
    end
  end

  describe '.contributor_types' do
    it 'returns an array of machine-readable type names' do
      type = DeedType::PAGE_TRANSCRIPTION
      expect(DeedType.contributor_types).to include(type)
      expect(DeedType.contributor_types).to be_a_kind_of(Array)
    end

    it 'excludes the "Work Added" type' do
      type = DeedType::WORK_ADDED
      expect(DeedType.contributor_types).to_not include(type)
    end
  end

  describe '.name' do
    it 'returns the human-readable name for a type' do
      type = DeedType::PAGE_TRANSCRIPTION
      human_readable = DeedType::TYPES[type]

      expect(DeedType.name(type)).to eq(human_readable)
    end
  end

  describe '.generate_zero_counts_hash' do
    it "returns a hash with all #{types_count} keys accounted for" do
      expect(DeedType.all_types).to eq(DeedType.generate_zero_counts_hash.keys)
      expect(DeedType.generate_zero_counts_hash.length).to eq(types_count)
    end

    it 'returns 0 for the value of every pair' do
      all_values = DeedType.generate_zero_counts_hash.values
      expect(all_values.uniq).to eq([0])
    end
  end
end
