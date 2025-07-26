require 'rails_helper'

RSpec.describe Article, type: :model do
  describe '#possible_duplicates' do
    let(:collection) { create(:collection) }
    let(:article) { create(:article, collection: collection, title: "F. R. Calvert") }

    context 'word filtering for duplicate detection' do
      it 'excludes very short words to reduce false positives' do
        # Create a test article with short common words
        test_article = build(:article, collection: collection, title: "Dr. Smith")
        
        # Mock the collection.articles scope to avoid database queries
        allow(test_article.collection).to receive(:articles).and_return(Article.none)
        
        # Test that the word processing excludes "Dr" but includes "Smith"
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.length >= 3 }
        
        expect(words).to eq(["Smith"])
        expect(words).not_to include("Dr")
      end

      it 'filters single letters and very short words' do
        test_article = build(:article, collection: collection, title: "A B Mr")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.length >= 3 }
        
        expect(words).to be_empty
      end

      it 'preserves meaningful words of 3+ characters' do
        test_article = build(:article, collection: collection, title: "John Robert Calvert")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.length >= 3 }
        words.sort! { |x,y| x.length <=> y.length }
        words.reverse!
        
        expect(words).to eq(["Calvert", "Robert", "John"])
      end
    end
  end
end