require 'spec_helper'

# SEC-04: every FacetsController action requires the collection owner (or an admin), and
# enable / disable no longer go over GET. Facet lookups go through @collection, so ids from
# another collection can't be used.
RSpec.describe FacetsController do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  # A work makes the collection viewable (Collection#show_to? requires works), so denied
  # signed-in users land on the collection page. Its metadata is written with update_column
  # because Work#save_metadata would build the coverage that enable is meant to backfill.
  let!(:work) do
    create(:work, collection: collection, owner_user_id: owner.id).tap do |work|
      work.update_column(:original_metadata, [{ label: 'Date', value: '1900' }].to_json)
    end
  end

  let!(:co_owner) { create(:unique_user, :owner).tap { |user| collection.owners << user } }
  let!(:stranger) { create(:unique_user) }
  let!(:admin) { create(:unique_user, :admin) }

  # A second collection owned by someone else, for the cross-collection cases.
  let!(:other_owner) { create(:unique_user, :owner) }
  let!(:other_collection) { create(:collection, owner_user_id: other_owner.id, works: []) }
  let!(:other_coverage) { create(:metadata_coverage, collection: other_collection, key: 'Date') }
  let!(:other_config) do
    create(:facet_config, metadata_coverage: other_coverage, label: { en: 'Other' }.to_json, order: 1)
  end

  def expect_denied_signed_out
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(dashboard_path)
  end

  def expect_denied_signed_in
    expect(response).to have_http_status(:see_other)
    expect(response).to redirect_to(collection_path(owner, collection))
    expect(flash[:error]).to eq(I18n.t('permission_denied'))
  end

  describe 'PATCH enable' do
    let(:params) { { collection_id: collection.id } }

    def expect_unchanged
      expect(collection.reload.facets_enabled).to be(false)
      expect(collection.metadata_coverages).to be_empty
    end

    it 'denies a signed-out user' do
      patch facets_enable_path, params: params

      expect_denied_signed_out
      expect_unchanged
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      patch facets_enable_path, params: params

      expect_denied_signed_in
      expect_unchanged
    end

    it 'denies a non-owner on a private collection without a server error' do
      collection.update!(visibility: :private)
      login_as stranger
      patch facets_enable_path, params: params

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(dashboard_path)
      expect_unchanged
    end

    it 'denies a missing collection_id' do
      login_as owner
      patch facets_enable_path

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'denies an unknown collection_id' do
      login_as owner
      patch facets_enable_path, params: { collection_id: 'no-such-collection' }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(dashboard_path)
    end

    it 'enables facets and builds metadata coverage from work metadata for the owner' do
      login_as owner
      patch facets_enable_path, params: params

      expect(response).to redirect_to(collection_facets_path(owner, collection))
      expect(collection.reload.facets_enabled).to be(true)
      expect(collection.metadata_coverages.pluck(:key)).to eq(['Date'])
      expect(collection.facet_configs.count).to eq(1)
    end

    it 'allows a co-owner' do
      login_as co_owner
      patch facets_enable_path, params: params

      expect(collection.reload.facets_enabled).to be(true)
    end

    it 'allows an admin' do
      login_as admin
      patch facets_enable_path, params: params

      expect(collection.reload.facets_enabled).to be(true)
    end

    it 'acts on the parent collection when given a document set' do
      collection.update!(supports_document_sets: true)
      document_set = create(:document_set, collection_id: collection.id, owner_user_id: owner.id)
      login_as owner
      patch facets_enable_path, params: { collection_id: document_set.slug }

      expect(response).to redirect_to(collection_facets_path(owner, collection))
      expect(collection.reload.facets_enabled).to be(true)
    end

    it 'is no longer routed over GET' do
      # The GET now falls through to the /:user_slug/:collection_id catch-all.
      expect(Rails.application.routes.recognize_path('/facets/enable', method: :get))
        .not_to include(controller: 'facets')

      login_as owner
      get '/facets/enable', params: params

      expect(collection.reload.facets_enabled).to be(false)
    end
  end

  describe 'PATCH disable' do
    let(:params) { { collection_id: collection.id } }

    before { collection.update!(facets_enabled: true) }

    it 'denies a signed-out user' do
      patch facets_disable_path, params: params

      expect_denied_signed_out
      expect(collection.reload.facets_enabled).to be(true)
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      patch facets_disable_path, params: params

      expect_denied_signed_in
      expect(collection.reload.facets_enabled).to be(true)
    end

    it 'disables facets for the owner' do
      login_as owner
      patch facets_disable_path, params: params

      expect(response).to redirect_to(edit_collection_path(owner, collection))
      expect(collection.reload.facets_enabled).to be(false)
    end

    it 'allows an admin' do
      login_as admin
      patch facets_disable_path, params: params

      expect(collection.reload.facets_enabled).to be(false)
    end

    it 'is no longer routed over GET' do
      # The GET now falls through to the /:user_slug/:collection_id catch-all.
      expect(Rails.application.routes.recognize_path('/facets/disable', method: :get))
        .not_to include(controller: 'facets')

      login_as owner
      get '/facets/disable', params: params

      expect(collection.reload.facets_enabled).to be(true)
    end
  end

  describe 'POST update' do
    let!(:coverage) { create(:metadata_coverage, collection: collection, key: 'Date') }
    let!(:facet_config) { create(:facet_config, metadata_coverage: coverage, input_type: 'date') }

    let(:params) do
      {
        collection_id: collection.id,
        metadata: { 'Date' => { label: 'Localized Date', input_type: 'text', order: '1' } }
      }
    end

    def expect_unchanged
      facet_config.reload
      expect(facet_config.label).to be_nil
      expect(facet_config.input_type).to eq('date')
      expect(facet_config.order).to be_nil
    end

    it 'denies a signed-out user' do
      post facets_update_path, params: params

      expect_denied_signed_out
      expect_unchanged
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      post facets_update_path, params: params

      expect_denied_signed_in
      expect_unchanged
    end

    it 'denies an owner of another collection' do
      login_as other_owner
      post facets_update_path, params: params

      expect_denied_signed_in
      expect_unchanged
    end

    it 'updates facet settings for the owner' do
      login_as owner
      post facets_update_path, params: params

      expect(response).to redirect_to(collection_facets_path(owner, collection))
      facet_config.reload
      expect(facet_config.input_type).to eq('text')
      expect(facet_config.order).to eq(0) # renumbered to contiguous 0-indexed values
      expect(JSON.parse(facet_config.label)['en']).to eq('Localized Date')
    end

    it 'allows a co-owner' do
      login_as co_owner
      post facets_update_path, params: params

      expect(facet_config.reload.input_type).to eq('text')
    end

    it 'leaves another collection\'s facet with the same key alone' do
      login_as owner
      post facets_update_path, params: params

      expect(other_config.reload.label).to eq({ en: 'Other' }.to_json)
      expect(other_config.order).to eq(1)
    end

    it 're-renders the form with the errors for an invalid order' do
      login_as owner
      post facets_update_path, params: params.deep_merge(metadata: { 'Date' => { order: '42' } })

      expect(response).to have_http_status(:ok)
      expect(response).to render_template('collection/facets')
      expect(response.body).to include('Order is not included in the list')
    end
  end

  describe 'GET localize' do
    let!(:coverage) { create(:metadata_coverage, collection: collection, key: 'Date') }
    let!(:facet_config) { create(:facet_config, metadata_coverage: coverage, label: { en: 'Date' }.to_json) }

    it 'denies a signed-out user' do
      get facets_localize_path(collection_id: collection.slug)

      expect_denied_signed_out
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      get facets_localize_path(collection_id: collection.slug)

      expect_denied_signed_in
    end

    it 'renders the form for the owner' do
      login_as owner
      get facets_localize_path(collection_id: collection.slug)

      expect(response).to have_http_status(:ok)
      expect(response).to render_template('collection/localize')
      expect(response.body).to include("action=\"#{facets_update_localization_path}\"")
    end

    it 'renders for the owner in a document set, posting the parent collection id' do
      collection.update!(supports_document_sets: true)
      document_set = create(:document_set, collection_id: collection.id, owner_user_id: owner.id)
      login_as owner
      get facets_localize_path(collection_id: document_set.slug)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("value=\"#{collection.id}\"")
      expect(response.body).to include("facets[#{facet_config.id}][en]")
    end
  end

  describe 'POST update_localization' do
    let!(:coverage) { create(:metadata_coverage, collection: collection, key: 'Date') }
    let!(:facet_config) { create(:facet_config, metadata_coverage: coverage, label: { en: 'Date' }.to_json) }

    let(:params) do
      { collection_id: collection.id, facets: { facet_config.id.to_s => { en: 'Date', es: 'Fecha' } } }
    end

    it 'denies a signed-out user' do
      post facets_update_localization_path, params: params

      expect_denied_signed_out
      expect(facet_config.reload.label).to eq({ en: 'Date' }.to_json)
    end

    it 'denies a signed-in non-owner' do
      login_as stranger
      post facets_update_localization_path, params: params

      expect_denied_signed_in
      expect(facet_config.reload.label).to eq({ en: 'Date' }.to_json)
    end

    it 'denies a non-owner XHR with the legacy ajax redirect' do
      login_as stranger
      post facets_update_localization_path, params: params, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.location).to eq(collection_path(owner, collection))
      expect(facet_config.reload.label).to eq({ en: 'Date' }.to_json)
    end

    it 'updates localized labels for the owner' do
      login_as owner
      post facets_update_localization_path, params: params, xhr: true

      expect(response).to have_http_status(:created)
      expect(response.location).to eq(collection_facets_path(owner, collection))
      expect(facet_config.reload.label).to eq({ 'en' => 'Date', 'es' => 'Fecha' }.to_json)
    end

    it 'allows an admin' do
      login_as admin
      post facets_update_localization_path, params: params, xhr: true

      expect(facet_config.reload.label).to eq({ 'en' => 'Date', 'es' => 'Fecha' }.to_json)
    end

    it 'ignores a facet config from another collection' do
      login_as owner
      post facets_update_localization_path, params: {
        collection_id: collection.id,
        facets: { other_config.id.to_s => { en: 'Hijacked' } }
      }, xhr: true

      expect(other_config.reload.label).to eq({ en: 'Other' }.to_json)
    end

    it 'denies a missing collection_id without a server error' do
      login_as owner
      post facets_update_localization_path, params: params.except(:collection_id)

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(dashboard_path)
    end
  end
end
