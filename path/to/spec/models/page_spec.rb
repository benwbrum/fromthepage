# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Page, type: :model do
  it 'decrements page count when marked inactive' do
    page = create(:page)
    expect { page.mark_inactive }.to change { page.page_count }.by(-1)
  end

  it 'does not decrement page count when not marked inactive' do
    page = create(:page)
    expect { page.update(page_count: page.page_count + 1) }.not_to change { page.page_count }
  end
end