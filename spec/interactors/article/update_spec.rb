require 'spec_helper'

describe Article::Update do
  let!(:user) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: user.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: user.id) }
  let!(:related_page) { create(:page, work: work, source_text: '[[Original]]', source_translation: '[[Original]]') }

  let!(:article) do
    create(:article, title: 'Original', collection: collection, pages: [related_page])
  end

  let!(:source_article) do
    create(:article, collection: collection.reload)
  end
  let!(:article_article_link) do
    create(:article_article_link, source_article: source_article, target_article: article)
  end

  let(:category_ids) { [] }

  let(:latitude) { nil }
  let(:longitude) { nil }
  let(:article_title) { 'New' }
  let(:article_params) do
    {
      title: article_title,
      uri: 'www.new-uri.com',
      source_text: 'New source text',
      latitude: latitude,
      longitude: longitude,
      category_ids: category_ids
    }
  end

  let(:result) do
    described_class.new(
      article: article.reload,
      article_params: article_params
    ).call
  end

  it 'updates article and source texts of related models' do
    expect(Article::RenameJob).to receive(:perform_later).with(
      article_id: article.id, old_name: 'Original', new_name: 'New'
    ).and_call_original

    # Set source text like this to avoid before save callbacks
    source_article.update_column(:source_text, '[[Original]]')

    expect(result.success?).to be_truthy
    expect(result.notice).to eq(I18n.t('article.update.subject_successfully_updated'))
    expect(result.article).to have_attributes(
      title: 'New',
      uri: 'www.new-uri.com',
      source_text: 'New source text'
    )
  end

  context 'when unchanged title' do
    let(:article_title) { 'Original' }

    it 'updates article without renaming source texts' do
      expect(Article::RenameJob).not_to receive(:perform_later)

      expect(result.success?).to be_truthy
      expect(result.notice).to eq(I18n.t('article.update.subject_successfully_updated'))
      expect(result.article).to have_attributes(
        title: 'Original',
        uri: 'www.new-uri.com',
        source_text: 'New source text'
      )
    end
  end

  context 'when gis truncated' do
    let(:latitude) { '1.123456789' }
    let(:longitude) { '1.123456789' }

    it 'updates article' do
      expect(result.success?).to be_truthy
      expect(result.notice).to eq(
        I18n.t('article.update.subject_successfully_updated') +
        I18n.t('article.update.gis_coordinates_truncated', precision: GIS_DECIMAL_PRECISION,
                                                           count: GIS_DECIMAL_PRECISION)
      )
      expect(result.article).to have_attributes(
        title: 'New',
        uri: 'www.new-uri.com',
        source_text: 'New source text',
        latitude: 1.12346,
        longitude: 1.12346
      )
    end
  end

  context 'when adding category' do
    let!(:category) { create(:category) }
    let(:category_ids) { [category.id] }

    it 'updates article' do
      expect(result.success?).to be_truthy
      expect(result.article.categories.first).to eq(category)
    end
  end

  context 'with invalid params' do
    let(:article_params) do
      {
        title: ''
      }
    end

    it 'fails to update article' do
      expect(result.success?).to be_falsey
    end
  end
end
