require 'spec_helper'

RSpec.describe FacetConfig, type: :model do
  describe '#localized_label' do
    it 'returns nil without a label' do
      expect(build(:facet_config, label: nil).localized_label(:en)).to be_nil
    end

    it 'returns the requested locale label' do
      facet = build(:facet_config, label: { en: 'Title', fr: 'Titre' }.to_json)

      expect(facet.localized_label(:fr)).to eq('Titre')
    end

    it 'falls back to the first label when the locale is missing' do
      facet = build(:facet_config, label: { en: 'Title', fr: 'Titre' }.to_json)

      expect(facet.localized_label(:de)).to eq('Title')
    end
  end

  describe 'validations' do
    it 'allows text facet orders from 0 through 9' do
      expect(build(:facet_config, input_type: 'text', order: 0)).to be_valid
      expect(build(:facet_config, input_type: 'text', order: 9)).to be_valid
      expect(build(:facet_config, input_type: 'text', order: 10)).not_to be_valid
    end

    it 'allows date facet orders from 0 through 2' do
      expect(build(:facet_config, input_type: 'date', order: 0)).to be_valid
      expect(build(:facet_config, input_type: 'date', order: 2)).to be_valid
      expect(build(:facet_config, input_type: 'date', order: 3)).not_to be_valid
    end

    it 'allows blank orders' do
      expect(build(:facet_config, input_type: 'text', order: nil)).to be_valid
    end
  end

  describe '.update_facets' do
    let(:collection) { build_stubbed(:collection) }
    let(:work) { build_stubbed(:work, collection: collection) }

    it 'does not update work facets when collection facets are disabled' do
      allow(collection).to receive(:facets_enabled?).and_return(false)
      allow(described_class).to receive(:update_work_facet)

      described_class.update_facets(work)

      expect(described_class).not_to have_received(:update_work_facet)
    end

    it 'updates work facets when collection facets are enabled' do
      allow(collection).to receive(:facets_enabled?).and_return(true)
      allow(described_class).to receive(:update_work_facet)

      described_class.update_facets(work)

      expect(described_class).to have_received(:update_work_facet).with(work, collection)
    end
  end

  describe '.update_work_facet' do
    it 'stores stripped metadata text in the configured string facet' do
      collection = create(:collection, facets_enabled: true)
      work = create(:work, collection: collection, original_metadata: [{ 'label' => 'Subject', 'value' => '<b>Botany</b>' }].to_json)
      coverage = create(:metadata_coverage, collection: collection, key: 'Subject')
      create(:facet_config, metadata_coverage: coverage, input_type: 'text', order: 0)
      work.create_work_facet!

      described_class.update_work_facet(work, collection)

      expect(work.reload.work_facet.s0).to eq('Botany')
    end
  end
end
