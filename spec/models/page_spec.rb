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

  
  describe '#image_url_for_download' do
    context 'when neither sc_canvas nor ia_leaf is present' do
      let(:default_url_options) { { host: 'localhost:3000' } }

      context 'when base_image contains spaces or parentheses' do
        let(:page) { build_stubbed(:page, base_image: '/image (1).jpg') }

        it 'returns the URL encoded characters' do
          page.sc_canvas=nil
          expect(page.image_url_for_download).to eq('http://localhost:3000/image%20(1).jpg')
        end
      end

    end
  end
end