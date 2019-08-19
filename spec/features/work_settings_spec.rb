require 'spec_helper'

describe "Work Settings" do
    before :all do
        @owner = User.find_by(login: OWNER)
    end
    before :each do
        login_as(@owner, :scope => :user)
        DatabaseCleaner.start
    end
    after :each do
        DatabaseCleaner.clean
    end

    let(:collection) { create(:collection, owner: @owner) }

    let(:work_no_ocr){ create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: false) }
    let(:page_no_ocr){ create(:page, work: work_no_ocr) }

    let(:work_ocr)   { create(:work, owner_user_id: @owner.id, collection: collection, ocr_correction: true) }
    let(:page_ocr)   { create(:page, work: work_ocr) }

    it "Enables OCR Correction" do
        # Visit work settings tab
        visit edit_collection_work_path(@owner, collection, work_no_ocr)
        expect(page).to have_content(work_no_ocr.title)
        expect(page).to have_unchecked_field('work_ocr_correction')
        # Find ocr checkbox, enable, and save
        page.check('work_ocr_correction')
        page.click_button('Save Changes')
        # Check for change
        expect(page).to have_checked_field('work_ocr_correction')
    end
    it "Disables OCR Correction" do
        # Visit work settings tab
        visit edit_collection_work_path(@owner, collection, work_ocr)
        expect(page).to have_content(work_ocr.title)
        expect(page).to have_checked_field('work_ocr_correction')
        # Find ocr checkbox, enable, and save
        page.uncheck('work_ocr_correction')
        page.click_button('Save Changes')
        # Check for change
        expect(page).to have_unchecked_field('work_ocr_correction')
    end
end