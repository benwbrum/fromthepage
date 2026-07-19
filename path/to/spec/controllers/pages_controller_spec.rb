# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  it 'marks page as inactive' do
    page = create(:page)
    expect { post :mark_inactive, params: { id: page.id } }.to change { page.reload.inactive? }.from(false).to(true)
  end
end