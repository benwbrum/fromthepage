require 'spec_helper'

describe Work::Export::Lib::Utils do
  describe '.latex_escape' do
    it 'escapes standard LaTeX special characters' do
      expect(described_class.latex_escape('hello & world')).to eq('hello \\& world')
      expect(described_class.latex_escape('100%')).to eq('100\\%')
      expect(described_class.latex_escape('$price')).to eq('\\$price')
    end

    it 'returns empty string for blank input' do
      expect(described_class.latex_escape('')).to eq('')
      expect(described_class.latex_escape(nil)).to eq('')
    end

    it 'leaves regular text unchanged' do
      expect(described_class.latex_escape('hello world')).to eq('hello world')
    end

    context 'with vulgar fraction Unicode characters (U+2150-U+215E)' do
      it 'converts ⅐ (U+2150) to nicefrac' do
        expect(described_class.latex_escape('⅐')).to eq('\\nicefrac{1}{7}')
      end

      it 'converts ⅑ (U+2151) to nicefrac' do
        expect(described_class.latex_escape('⅑')).to eq('\\nicefrac{1}{9}')
      end

      it 'converts ⅒ (U+2152) to nicefrac' do
        expect(described_class.latex_escape('⅒')).to eq('\\nicefrac{1}{10}')
      end

      it 'converts ⅓ (U+2153) to nicefrac' do
        expect(described_class.latex_escape('⅓')).to eq('\\nicefrac{1}{3}')
      end

      it 'converts ⅔ (U+2154) to nicefrac' do
        expect(described_class.latex_escape('⅔')).to eq('\\nicefrac{2}{3}')
      end

      it 'converts ⅕ (U+2155) to nicefrac' do
        expect(described_class.latex_escape('⅕')).to eq('\\nicefrac{1}{5}')
      end

      it 'converts ⅖ (U+2156) to nicefrac' do
        expect(described_class.latex_escape('⅖')).to eq('\\nicefrac{2}{5}')
      end

      it 'converts ⅗ (U+2157) to nicefrac' do
        expect(described_class.latex_escape('⅗')).to eq('\\nicefrac{3}{5}')
      end

      it 'converts ⅘ (U+2158) to nicefrac' do
        expect(described_class.latex_escape('⅘')).to eq('\\nicefrac{4}{5}')
      end

      it 'converts ⅙ (U+2159) to nicefrac' do
        expect(described_class.latex_escape('⅙')).to eq('\\nicefrac{1}{6}')
      end

      it 'converts ⅚ (U+215A) to nicefrac' do
        expect(described_class.latex_escape('⅚')).to eq('\\nicefrac{5}{6}')
      end

      it 'converts ⅛ (U+215B) to nicefrac' do
        expect(described_class.latex_escape('⅛')).to eq('\\nicefrac{1}{8}')
      end

      it 'converts ⅜ (U+215C) to nicefrac' do
        expect(described_class.latex_escape('⅜')).to eq('\\nicefrac{3}{8}')
      end

      it 'converts ⅝ (U+215D) to nicefrac' do
        expect(described_class.latex_escape('⅝')).to eq('\\nicefrac{5}{8}')
      end

      it 'converts ⅞ (U+215E) to nicefrac' do
        expect(described_class.latex_escape('⅞')).to eq('\\nicefrac{7}{8}')
      end

      it 'converts fractions embedded in a sentence' do
        expect(described_class.latex_escape('Add ⅛ cup sugar')).to eq('Add \\nicefrac{1}{8} cup sugar')
      end

      it 'converts multiple different fractions in one string' do
        expect(described_class.latex_escape('⅓ and ⅔ and ⅛')).to eq('\\nicefrac{1}{3} and \\nicefrac{2}{3} and \\nicefrac{1}{8}')
      end
    end
  end
end
