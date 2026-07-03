# frozen_string_literal: true

require 'spec_helper'

describe 'forum topic form' do
  let(:owner) { create(:unique_user, :owner) }
  let(:collection) do
    create(
      :collection,
      owner_user_id: owner.id,
      works: [],
      title: "Forum Topic Form #{SecureRandom.hex(4)}"
    )
  end

  before do
    collection.enable_messageboards
    login_as(owner, scope: :user)
  end

  it 'renders create topic controls in a collapsed section' do
    visit collection_path(owner, collection)
    click_link 'Forum'
    click_link 'General'

    expect(page).to have_css('details.thredded--new-topic-accordion')
    expect(page).not_to have_button(I18n.t('thredded.topics.form.create_btn'))
    expect(page).to have_button(I18n.t('thredded.topics.form.create_btn'), visible: :hidden)
  end
end
