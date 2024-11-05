require 'spec_helper'

describe Article::Update do
  let(:user) { User.find_by(login: OWNER) }
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

  let(:latitude) { nil }
  let(:longitude) { nil }
  let(:article_params) do
    {
      title: 'New',
      uri: 'www.new-uri.com',
      source_text: 'New source text',
      latitude: latitude,
      longitude: longitude
    }
  end

  let(:result) do
    described_class.call(
      article: article.reload,
      article_params: article_params
    )
  end

  it 'updates article and source texts of related models' do
    # Set source text like this to avoid before save callbacks
    source_article.update_column(:source_text, '[[Original]]')

    expect(result.success?).to be_truthy
    expect(result.notice).to eq(I18n.t('article.update.subject_successfully_updated'))
    expect(result.article).to have_attributes(
      title: 'New',
      uri: 'www.new-uri.com',
      source_text: 'New source text'
    )
    expect(related_page.reload).to have_attributes(
      source_text: '[[New|Original]]',
      source_translation: '[[New|Original]]'
    )
    expect(source_article.reload).to have_attributes(source_text: '[[New|Original]]')
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
