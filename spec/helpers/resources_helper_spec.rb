require 'spec_helper'

RSpec.describe ResourcesHelper, type: :helper do
  describe '#flash_aria_attributes' do
    context 'for notice flash type' do
      it 'returns status role with polite aria-live' do
        attributes = helper.flash_aria_attributes('notice')
        
        expect(attributes[:role]).to eq('status')
        expect(attributes[:'aria-live']).to eq('polite')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end

    context 'for info flash type' do
      it 'returns status role with polite aria-live' do
        attributes = helper.flash_aria_attributes('info')
        
        expect(attributes[:role]).to eq('status')
        expect(attributes[:'aria-live']).to eq('polite')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end

    context 'for alert flash type' do
      it 'returns alert role with assertive aria-live' do
        attributes = helper.flash_aria_attributes('alert')
        
        expect(attributes[:role]).to eq('alert')
        expect(attributes[:'aria-live']).to eq('assertive')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end

    context 'for error flash type' do
      it 'returns alert role with assertive aria-live' do
        attributes = helper.flash_aria_attributes('error')
        
        expect(attributes[:role]).to eq('alert')
        expect(attributes[:'aria-live']).to eq('assertive')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end

    context 'for unknown flash type' do
      it 'defaults to status role with polite aria-live' do
        attributes = helper.flash_aria_attributes('unknown')
        
        expect(attributes[:role]).to eq('status')
        expect(attributes[:'aria-live']).to eq('polite')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end

    context 'with symbol type' do
      it 'works correctly with symbol input' do
        attributes = helper.flash_aria_attributes(:notice)
        
        expect(attributes[:role]).to eq('status')
        expect(attributes[:'aria-live']).to eq('polite')
        expect(attributes[:'aria-atomic']).to eq('true')
      end
    end
  end

  describe '#flash_icons' do
    it 'returns the correct icon mapping' do
      icons = helper.flash_icons
      
      expect(icons[:notice]).to eq('#icon-check-sign')
      expect(icons[:alert]).to eq('#icon-warning-sign')
      expect(icons[:error]).to eq('#icon-remove-sign')
      expect(icons[:info]).to eq('#icon-warning-sign')
    end
  end
end