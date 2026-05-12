require 'spec_helper'

describe 'IIIF Canvas Status API' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, subjects_disabled: false) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }

  describe 'GET /iiif/:work_id/:page_id/status' do
    let(:action) { get "/iiif/#{work.id}/#{page.id}/status" }

    context 'when page has translation_status indexed (wiki markup with subject links)' do
      let!(:page) { create(:page, work: work, status: :transcribed, translation_status: :indexed) }

      it 'includes hasTranslation in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end

    context 'when page has translation_status translated' do
      let!(:page) { create(:page, work: work, status: :transcribed, translation_status: :translated) }

      it 'includes hasTranslation in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end
    end

    context 'when page has translation_status needs_review' do
      let!(:page) { create(:page, work: work, status: :transcribed, translation_status: :needs_review) }

      it 'includes hasTranslation in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranslation')
      end

      it 'includes translationNeedsReview in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('translationNeedsReview')
      end
    end

    context 'when page has translation_status new (no translation yet)' do
      let!(:page) { create(:page, work: work, status: :transcribed, translation_status: :new) }

      it 'does not include hasTranslation in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).not_to include('hasTranslation')
      end
    end

    context 'when page has translation_status blank' do
      let!(:page) { create(:page, work: work, status: :blank, translation_status: :blank) }

      it 'does not include hasTranslation in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).not_to include('hasTranslation')
      end

      it 'includes markedBlank in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('markedBlank')
      end
    end

    context 'when page transcription is indexed' do
      let!(:page) { create(:page, work: work, status: :indexed, translation_status: :new) }

      it 'includes hasTranscript in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasTranscript')
      end

      it 'includes hasSubjectTags in pageStatus' do
        action
        json = JSON.parse(response.body)
        expect(json['pageStatus']).to include('hasSubjectTags')
      end
    end
  end
end
