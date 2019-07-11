require 'spec_helper'

RSpec.describe Page, type: :model do
#   context "associations" do
#     it { should belong_to(:article) }
#   end

#   context "validations" do
#     it { should validate_inclusion_of(:deed_type).in_array(DeedType.all_types) }
#   end

  describe '#validate_blank_page' do
    let(:page) { build_stubbed(:page) }
    it 'sets Page::STATUS_BLANK' do
        page.status = Page::STATUS_BLANK
        page.validate_blank_page

        expect(page.status).to eq(Page::STATUS_BLANK)
    end
    it 'keeps Page::STATUS_BLANK when text is blank' do
        page.status = Page::STATUS_BLANK
        page.validate_blank_page

        page.source_text = ''

        expect(page.status).to eq(Page::STATUS_BLANK)
    end
    it 'resets page status if empty and not marked blank' do
        page.status = Page::STATUS_TRANSCRIBED
        page.source_text = ''
    
        page.validate_blank_page

        expect(page.status).to eq(nil)
    end
    it 'does not reset page status is text is not empty' do
        page.status = Page::STATUS_BLANK
        page.source_text = 'Testing'
        
        page.validate_blank_page

        expect(page.status).to eq(Page::STATUS_BLANK)
    end
  end
end