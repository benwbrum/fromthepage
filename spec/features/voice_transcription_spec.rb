require 'spec_helper'

describe 'voice transcription' do
  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id, voice_recognition: voice_recognition, works: []) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id, supports_translation: true) }
  let!(:page) { create(:page, work: work) }
  let!(:article) { create(:article, collection: collection, pages: [page]) }

  let(:voice_recognition) { false }

  before do
    login_as(owner, scope: :user)
  end

  def visit_transcribe_page
    visit collection_transcribe_page_path(collection.owner, collection, work, page)

    if page.has_content?('Facsimile')
      page.find('.tabs').click_link('Transcribe')
    end
  end

  it 'does not show microphones when voice transcription is disabled' do
    visit_transcribe_page

    expect(page).not_to have_selector('.voice-recognition')
    expect(page).not_to have_selector('#start_img')
    expect(page).not_to have_selector('.voice-info')
    expect(page).not_to have_selector('#start_img_note')

    page.find('.tabs').click_link('Translate')
    expect(page).not_to have_selector('.voice-recognition')
    expect(page).not_to have_selector('#start_img')

    visit collection_article_edit_path(collection.owner, collection, article)
    expect(page).not_to have_selector('.article-editarea')
    expect(page).not_to have_selector('#start_img')
  end

  context 'when voice transcription is enabled' do
    let(:voice_recognition) { true }

    it 'shows microphones on transcription, translation, and article pages' do
      visit_transcribe_page

      expect(page).to have_selector('.voice-recognition')
      expect(page).to have_selector('#start_img')
      expect(page).to have_selector('#start_img_note')

      page.find('.tabs').click_link('Translate')
      expect(page).to have_selector('.voice-recognition')
      expect(page).to have_selector('#start_img')

      visit collection_article_edit_path(collection.owner, collection, article)
      expect(page).to have_selector('.article-editarea')
      expect(page).to have_selector('#start_img')
    end
  end

  it 'turns on voice transcription from collection settings', js: true do
    expect(collection.voice_recognition).to be false

    visit edit_collection_path(collection.owner, collection)
    page.find('.side-tabs').click_link('Look & Feel')
    page.check 'collection_voice_recognition'

    expect { collection.reload.voice_recognition }.to become(true)
  end

  context 'when voice transcription starts enabled' do
    let(:voice_recognition) { true }

    it 'turns off voice transcription from collection settings', js: true do
      expect(collection.voice_recognition).to be true

      visit edit_collection_path(collection.owner, collection)
      page.find('.side-tabs').click_link('Look & Feel')
      page.uncheck 'collection_voice_recognition'

      expect { collection.reload.voice_recognition }.to become(false)
    end
  end
end
