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

    it "Inherits transcription conventions from collection by default" do
        collection.update!(transcription_conventions: "Collection convention text")
        
        # Visit work settings tab
        visit edit_collection_work_path(@owner, collection, work_no_ocr)
        expect(page).to have_content(work_no_ocr.title)
        
        # Check that the transcription conventions field is empty (not pre-populated with collection conventions)
        conventions_field = page.find('#work_transcription_conventions')
        expect(conventions_field.value).to be_blank
        
        # Save without changing conventions
        page.click_button('Save Changes')
        
        # Verify work still inherits from collection
        work_no_ocr.reload
        expect(work_no_ocr.transcription_conventions).to be_nil
        expect(work_no_ocr.set_transcription_conventions).to eq("Collection convention text")
    end

    it "Allows overriding collection conventions at work level" do
        collection.update!(transcription_conventions: "Collection convention text")
        
        # Visit work settings tab
        visit edit_collection_work_path(@owner, collection, work_no_ocr)
        
        # Enter custom work conventions
        page.fill_in('work_transcription_conventions', with: 'Work-specific convention text')
        page.click_button('Save Changes')
        
        # Verify work has its own conventions
        work_no_ocr.reload
        expect(work_no_ocr.transcription_conventions).to eq('Work-specific convention text')
        expect(work_no_ocr.set_transcription_conventions).to eq('Work-specific convention text')
    end

    it "Reverts work conventions back to collection inheritance" do
        collection.update!(transcription_conventions: "Collection convention text")
        work_no_ocr.update!(transcription_conventions: "Work-specific convention")
        
        # Visit work settings tab
        visit edit_collection_work_path(@owner, collection, work_no_ocr)
        
        # Verify the revert button is visible
        expect(page).to have_button('Revert')
        
        # Clear the conventions field and save
        page.fill_in('work_transcription_conventions', with: '')
        page.click_button('Save Changes')
        
        # Verify work now inherits from collection
        work_no_ocr.reload
        expect(work_no_ocr.transcription_conventions).to be_nil
        expect(work_no_ocr.set_transcription_conventions).to eq("Collection convention text")
    end
end