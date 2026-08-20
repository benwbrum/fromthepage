# frozen_string_literal: true

require 'spec_helper'

describe 'work segmentation UI' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id, works: []) }
  let(:work) { create(:work, collection: collection, owner: owner) }

  before do
    login_as(owner, scope: :user)
  end

  after do
    Collection.where(owner_user_id: owner.id).find_each(&:destroy!) if owner&.persisted?
  end

  describe 'AI-detected split confirmation popover (1a)', js: true do
    let!(:first_page) { create(:page, work: work, position: 1, title: 'Letters to Rosannah, part one') }
    let!(:flagged_page) { create(:page, work: work, position: 2, is_first_page_candidate: true) }

    it 'opens a non-reflowing popover instead of expanding the banner in place' do
      visit collection_transcribe_page_path(owner, collection, work, flagged_page)

      expect(page).to have_content('This looks like a new document. Separate this into a new work?')
      expect(page).to have_no_css('.segmentation-popover.open')

      page.find('[data-segmentation-toggle]').click
      expect(page).to have_css('.segmentation-popover.open')
      expect(page.find('.segmentation-title-label')).to have_content('Title for pages 1–1')
      expect(page.find_field('new_work_title').value).to eq('Letters to Rosannah, part one')

      within('.segmentation-popover') { click_button 'Cancel' }
      expect(page).to have_no_css('.segmentation-popover.open')
      expect(work.reload.pages.count).to eq(2)

      page.find('[data-segmentation-toggle]').click
      within('.segmentation-popover') { click_button 'Split' }

      expect(page).to have_content('Created "Letters to Rosannah, part one" with 1 pages.')
      expect(work.reload.pages.count).to eq(1)

      new_work = Work.find_by!(title: 'Letters to Rosannah, part one')
      click_link 'View new work'
      expect(page).to have_current_path(collection_read_work_path(owner, collection, new_work))
      expect(page).to have_content('Letters to Rosannah, part one')
    end

    it 'sends the owner to the new work metadata form when they opt in' do
      visit collection_transcribe_page_path(owner, collection, work, flagged_page)

      page.find('[data-segmentation-toggle]').click
      within('.segmentation-popover') do
        check 'segmentation_edit_metadata_' + flagged_page.id.to_s
        click_button 'Split'
      end

      new_work = Work.find_by!(title: 'Letters to Rosannah, part one')
      expect(page).to have_current_path(edit_metadata_collection_work_path(owner, collection, new_work))
    end
  end

  describe 'human-in-the-loop split control (1b)', js: true do
    context 'when nothing in the work has been AI-flagged' do
      let!(:first_page) { create(:page, work: work, position: 1) }
      let!(:second_page) { create(:page, work: work, position: 2) }

      it 'does not show the scissors icon' do
        visit collection_transcribe_page_path(owner, collection, work, second_page)

        expect(page).to have_no_css('[data-segmentation-split-toggle]')
      end
    end

    context 'when another page in the work was flagged but the current page was not' do
      let!(:first_page) { create(:page, work: work, position: 1, title: 'Letter one') }
      let!(:second_page) { create(:page, work: work, position: 2) }
      let!(:third_page) { create(:page, work: work, position: 3, is_first_page_candidate: true) }

      it 'shows a quiet scissors control with the same title field as the AI popover' do
        visit collection_transcribe_page_path(owner, collection, work, second_page)

        expect(page).to have_no_content('This looks like a new document.')
        expect(page).to have_css('[data-segmentation-split-toggle]')
        expect(page).to have_no_css('.segmentation-split-strip')

        page.find('[data-segmentation-split-toggle]').click
        expect(page).to have_css('.segmentation-split-strip')
        expect(page).to have_content('Split this into a new work starting here?')
        within('.segmentation-split-strip') do
          expect(page).to have_css('.segmentation-title-label', text: 'Title for pages 1–1')
          expect(find_field('new_work_title').value).to eq('Letter one')
        end

        within('.segmentation-split-strip') { click_button 'Cancel' }
        expect(page).to have_no_css('.segmentation-split-strip.open')
        expect(work.reload.pages.count).to eq(3)

        page.find('[data-segmentation-split-toggle]').click
        within('.segmentation-split-strip') do
          fill_in 'new_work_title', with: 'Custom split title'
          click_link 'Split'
        end

        expect(page).to have_content('Created "Custom split title" with 1 pages.')
        expect(work.reload.pages.count).to eq(2)

        new_work = Work.find_by!(title: 'Custom split title')
        click_link 'View new work'
        expect(page).to have_current_path(collection_read_work_path(owner, collection, new_work))
      end
    end

    context 'when the owner opts to edit metadata after splitting' do
      let!(:first_page) { create(:page, work: work, position: 1, title: 'Letter one') }
      let!(:second_page) { create(:page, work: work, position: 2) }
      let!(:third_page) { create(:page, work: work, position: 3, is_first_page_candidate: true) }

      it 'sends the owner to the new work metadata form instead of the inline success banner' do
        visit collection_transcribe_page_path(owner, collection, work, second_page)

        page.find('[data-segmentation-split-toggle]').click
        within('.segmentation-split-strip') do
          check 'segmentation_split_edit_metadata_' + third_page.id.to_s
          click_link 'Split'
        end

        new_work = Work.find_by!(title: 'Letter one')
        expect(page).to have_current_path(edit_metadata_collection_work_path(owner, collection, new_work))
      end
    end
  end
end
