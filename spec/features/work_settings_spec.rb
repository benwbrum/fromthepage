require 'spec_helper'

describe "Work Settings" do
  let!(:owner) { User.find_by(login: OWNER) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }

  let!(:work_no_ocr) { create(:work, owner_user_id: owner.id, collection_id: collection.id, ocr_correction: false) }
  let!(:page_no_ocr) { create(:page, work_id: work_no_ocr.id) }

  let!(:work_ocr)   { create(:work, owner_user_id: owner.id, collection_id: collection.id, ocr_correction: true) }
  let!(:page_ocr)   { create(:page, work_id: work_ocr.id) }

  it "Enables OCR Correction", js: true do
    login_as(owner, scope: :user)

    # Visit work settings tab
    visit edit_collection_work_path(owner, collection, work_no_ocr)
    expect(page).to have_content(work_no_ocr.title)
    page.find('.side-tabs').click_link('Task Configuration')
    expect(page).to have_unchecked_field('work_ocr_correction')
    # Find ocr checkbox, enable, and save
    page.check('work_ocr_correction')
    expect(page).to have_content("Work updated successfully")
    # Check for change
    expect(page).to have_checked_field('work_ocr_correction')
  end

  it "Disables OCR Correction", js: true do
    login_as(owner, scope: :user)

    # Visit work settings tab
    visit edit_collection_work_path(owner, collection, work_ocr)
    expect(page).to have_content(work_ocr.title)
    page.find('.side-tabs').click_link('Task Configuration')
    expect(page).to have_checked_field('work_ocr_correction')
    # Find ocr checkbox, enable, and save
    page.uncheck('work_ocr_correction')
    expect(page).to have_content("Work updated successfully")
    # Check for change
    expect(page).to have_unchecked_field('work_ocr_correction')
  end

  it "Inherits transcription conventions from collection by default", js: true do
    login_as(owner, scope: :user)

    collection.update!(transcription_conventions: "Collection convention text")

    # Visit work settings tab
    visit edit_collection_work_path(owner, collection, work_no_ocr)
    expect(page).to have_content(work_no_ocr.title)

    # Check that the transcription conventions field is empty (not pre-populated with collection conventions)
    conventions_field = page.find('#work_transcription_conventions')
    expect(conventions_field.value).to be_blank

    # Save without changing conventions
    script = "$('#collection-settings-save').click()"
    page.execute_script(script)
    expect(page).to have_content("Work updated successfully")

    # Verify work still inherits from collection
    work_no_ocr.reload
    expect(work_no_ocr.transcription_conventions).to be_nil
    expect(work_no_ocr.set_transcription_conventions).to eq("Collection convention text")
  end

  it "Allows overriding collection conventions at work level", js: true do
    login_as(owner, scope: :user)

    collection.update!(transcription_conventions: "Collection convention text")

    # Visit work settings tab
    visit edit_collection_work_path(owner, collection, work_no_ocr)

    # Enter custom work conventions
    page.fill_in('work_transcription_conventions', with: 'Work-specific convention text')
    script = "$('#collection-settings-save').click()"
    page.execute_script(script)
    expect(page).to have_content("Work updated successfully")

    # Verify work has its own conventions
    work_no_ocr.reload
    expect(work_no_ocr.transcription_conventions).to eq('Work-specific convention text')
    expect(work_no_ocr.set_transcription_conventions).to eq('Work-specific convention text')
  end

  it "Reverts work conventions back to collection inheritance", js: true do
    login_as(owner, scope: :user)

    collection.update!(transcription_conventions: "Collection convention text")
    work_no_ocr.update!(transcription_conventions: "Work-specific convention")

    # Visit work settings tab
    visit edit_collection_work_path(owner, collection, work_no_ocr)

    # Verify the revert button is visible
    expect(page).to have_button('Revert')

    # Clear the conventions field and save
    page.fill_in('work_transcription_conventions', with: '')

    script = "$('#collection-settings-save').click()"
    page.execute_script(script)

    expect(page).to have_content("Work updated successfully")

    # Verify work now inherits from collection
    work_no_ocr.reload
    expect(work_no_ocr.transcription_conventions).to be_nil
    expect(work_no_ocr.set_transcription_conventions).to eq("Collection convention text")
  end
end
