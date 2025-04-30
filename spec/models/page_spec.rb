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
    it 'sets :blank' do
      page.status = :blank
      page.validate_blank_page

      expect(page.status_blank?).to be_truthy
    end
    it 'keeps :blank when text is blank' do
      page.status = :blank
      page.validate_blank_page

      page.source_text = ''

      expect(page.status_blank?).to be_truthy
    end
    it 'resets page status if empty and not marked blank' do
      page.status = :transcribed
      page.source_text = ''

      page.validate_blank_page

      expect(page.status_new?).to be_truthy
    end
    it 'does not reset page status is text is not empty' do
      page.status = :blank
      page.source_text = 'Testing'

      page.validate_blank_page

      expect(page.status_blank?).to be_truthy
    end
  end
end
