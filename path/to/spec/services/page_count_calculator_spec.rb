# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageCountCalculator, type: :model do
  let(:pages) { create_list(:page, 5) }

  it 'calculates page count correctly' do
    expect(PageCountCalculator.new.calculate_page_count(pages)).to eq(5)
  end

  it 'updates page count correctly' do
    page = create(:page)
    expect { PageCountCalculator.new.update_page_count(page, true) }.to change { page.page_count }.by(-1)
  end
end