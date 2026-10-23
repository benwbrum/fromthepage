require 'spec_helper'

RSpec.describe FacetsController do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }

  before { login_as owner }

  describe '#enable' do
    it 'enables facets and creates metadata coverage from work metadata' do
      create(:work, collection: collection, owner_user_id: owner.id, original_metadata: [{ label: 'Date', value: '1900' }].to_json)

      get facets_enable_path, params: { collection_id: collection.id }

      expect(response).to redirect_to(collection_facets_path(owner, collection))
      expect(collection.reload.facets_enabled).to eq(true)
      expect(collection.metadata_coverages.pluck(:key)).to include('Date')
    end
  end

  describe '#disable' do
    it 'disables facets' do
      collection.update!(facets_enabled: true)

      get facets_disable_path, params: { collection_id: collection.id }

      expect(response).to redirect_to(edit_collection_path(owner, collection))
      expect(collection.reload.facets_enabled).to eq(false)
    end
  end

  describe '#update' do
    let!(:metadata_coverage) { create(:metadata_coverage, collection: collection, key: 'Date') }
    let!(:facet_config) { create(:facet_config, metadata_coverage: metadata_coverage) }

    it 'updates facet settings' do
      post facets_update_path, params: {
        collection_id: collection.id,
        metadata: {
          'Date' => {
            label: 'Localized Date',
            input_type: 'text',
            order: '1'
          }
        }
      }

      expect(response).to redirect_to(collection_facets_path(owner, collection))
      expect(facet_config.reload.input_type).to eq('text')
      expect(JSON.parse(facet_config.label)['en']).to eq('Localized Date')
    end
  end

  describe '#localize' do
    it 'renders localization form' do
      get facets_localize_path(collection_id: collection.id)

      expect(response).to have_http_status(:ok)
    end
  end

  describe '#update_localization' do
    let!(:metadata_coverage) { create(:metadata_coverage, collection: collection, key: 'Date') }
    let!(:facet_config) { create(:facet_config, metadata_coverage: metadata_coverage) }

    it 'updates localized labels' do
      post facets_update_localization_path, params: {
        collection_id: collection.id,
        facets: {
          facet_config.id.to_s => { en: 'Date', es: 'Fecha' }
        }
      }

      expect(facet_config.reload.label).to eq({ 'en' => 'Date', 'es' => 'Fecha' }.to_json)
    end
  end
end
