# frozen_string_literal: true

require 'spec_helper'

# SEC-03: the owner's category menu on the subjects page. Guards the PATCH / DELETE links
# (jquery_ujs) and the litebox forms, which must keep sending collection_id.
describe 'subject category actions' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection, owner_user_id: owner.id) }
  let!(:category) { create(:category, collection_id: collection.id, title: "Places #{SecureRandom.hex(4)}") }

  before do
    login_as(owner, scope: :user)
  end

  after do
    collection.destroy!
    owner.destroy!
  end

  def open_category_menu
    visit collection_subjects_path(owner, collection, selected_category_id: category.id)
    within("#category-#{category.id}") { find('dt.h5').click }
  end

  it 'enables and disables GIS for a category', js: true do
    open_category_menu
    within("#category-#{category.id}") { click_link I18n.t('article.list.enable_gis_for_category') }

    expect(page).to have_content(I18n.t('category.enable_gis.fields_enabled_for', title: category.title))
    expect(category.reload.gis_enabled).to be(true)

    open_category_menu
    within("#category-#{category.id}") { click_link I18n.t('article.list.disable_gis_for_category') }

    expect(page).to have_content(I18n.t('category.disable_gis.fields_disabled_for', title: category.title))
    expect(category.reload.gis_enabled).to be(false)
  end

  it 'renames a category through the edit form', js: true do
    new_title = "Renamed #{SecureRandom.hex(4)}"
    open_category_menu
    within("#category-#{category.id}") { click_link I18n.t('article.list.edit_category') }

    within('.litebox') do
      fill_in I18n.t('category.form.title'), with: new_title
      click_button I18n.t('category.edit.save_changes')
    end

    expect(page).to have_content(I18n.t('category.update.category_updated'))
    expect(category.reload.title).to eq(new_title)
  end

  it 'adds a child category through the new-category form', js: true do
    child_title = "Child #{SecureRandom.hex(4)}"
    open_category_menu
    within("#category-#{category.id}") { click_link I18n.t('article.list.add_child_category') }

    within('.litebox') do
      fill_in I18n.t('category.form.title'), with: child_title
      click_button I18n.t('category.add_new.create_category')
    end

    expect(page).to have_content(I18n.t('category.create.category_created'))
    child = collection.categories.find_by!(title: child_title)
    expect(child.parent).to eq(category)
  end

  it 'deletes a category after confirming', js: true do
    open_category_menu
    accept_confirm do
      within("#category-#{category.id}") { click_link I18n.t('article.list.delete_category') }
    end

    expect(page).to have_content(I18n.t('category.delete.category_deleted'))
    expect(Category.exists?(category.id)).to be(false)
  end
end
