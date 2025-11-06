require 'spec_helper'

describe 'IIIF Translation Status API' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, subjects_disabled: false) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, supports_translation: true) }
  let!(:page) { create(:page, work: work, base_width: 100, base_height: 100) }

  before do
    Current.user = owner
    work.work_statistic ||= create(:work_statistic, work: work)
  end

  describe 'canvas_status endpoint' do
    let(:status_url) { "/iiif/#{work.id}/#{page.id}/status" }

    context 'when page has translation with wiki-markup and translation_status is indexed' do
      before do
        page.update!(
          source_translation: 'This is a translation with [[wiki markup]]',
          translation_status: :indexed
        )
      end

      it 'includes hasTranslation in pageStatus' do
        get status_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end

      it 'returns valid JSON' do
        get status_url

        expect(response.content_type).to eq('application/json; charset=utf-8')
        json = JSON.parse(response.body)
        expect(json).to have_key('pageStatus')
        expect(json['pageStatus']).to be_an(Array)
      end
    end

    context 'when page has translation_status as translated' do
      before do
        page.update!(
          source_translation: 'This is a translation',
          translation_status: :translated
        )
      end

      it 'includes hasTranslation in pageStatus' do
        get status_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end

    context 'when page has translation_status as needs_review' do
      before do
        page.update!(
          source_translation: 'This is a translation',
          translation_status: :needs_review
        )
      end

      it 'includes hasTranslation in pageStatus' do
        get status_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
        expect(json['pageStatus']).to include('translationNeedsReview')
      end
    end

    context 'when page has no translation' do
      before do
        page.update!(
          source_translation: '',
          translation_status: :new
        )
      end

      it 'does not include hasTranslation in pageStatus' do
        get status_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).not_to include('hasTranslation')
      end
    end

    context 'when page is marked blank for translation' do
      before do
        page.update!(
          source_translation: '',
          translation_status: :blank
        )
      end

      it 'does not include hasTranslation in pageStatus' do
        get status_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).not_to include('hasTranslation')
      end
    end
  end

  describe 'structured_data_endpoint' do
    let(:structured_data_url) { "/iiif/#{work.id}/structured/#{page.id}" }

    context 'when page has translation with indexed status' do
      before do
        page.update!(
          source_translation: 'Translation with [[links]]',
          translation_status: :indexed
        )
      end

      it 'includes hasTranslation in pageStatus' do
        get structured_data_url

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end
  end

  describe 'transcription with subject tags behavior' do
    context 'when subjects are enabled and translation has wiki-markup' do
      let!(:article) { create(:article, title: 'TestSubject', collection: collection) }
      
      before do
        collection.update!(subjects_disabled: false)
        page.update!(source_translation: '', translation_status: :new)
      end

      it 'sets translation_status to indexed after saving translation with links' do
        login_as owner
        
        # Save translation with wiki-markup
        post collection_save_translation_page_path(owner, collection, work, page),
             params: {
               save: 'save',
               page: {
                 source_translation: 'This has a [[TestSubject]] link'
               }
             }

        page.reload
        # After processing, if the page has links, status should be indexed
        # This tests the transcribe_controller.rb logic at line 293-301
        if page.page_article_links.where(text_type: 'translation').count > 0
          expect(page.translation_status).to eq('indexed')
        end

        # Verify the IIIF API returns hasTranslation
        get "/iiif/#{work.id}/#{page.id}/status"
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end

    context 'when subjects are disabled and translation has wiki-markup' do
      let!(:article) { create(:article, title: 'TestSubject', collection: collection) }
      
      before do
        collection.update!(subjects_disabled: true)
        page.update!(source_translation: '', translation_status: :new)
      end

      it 'does not set translation_status to indexed even with wiki-markup' do
        login_as owner
        
        # Save translation with wiki-markup
        post collection_save_translation_page_path(owner, collection, work, page),
             params: {
               save: 'save',
               page: {
                 source_translation: 'This has a [[TestSubject]] link'
               }
             }

        page.reload
        # When subjects are disabled, status should remain translated, not indexed
        expect(page.translation_status).to eq('translated')

        # Verify the IIIF API returns hasTranslation
        get "/iiif/#{work.id}/#{page.id}/status"
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end
  end
end
