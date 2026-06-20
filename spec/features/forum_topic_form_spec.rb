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

  it 'shows a visible submit button for starting a topic' do
    visit collection_path(owner, collection)
    click_link 'Forum'
    click_link 'General'

    expect(page).to have_field('topic_title')
    expect(page).to have_button(I18n.t('thredded.topics.form.create_btn'))
  end
end
