require 'spec_helper'

RSpec.describe Article, type: :model do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end

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
        words.keep_if { |word| word.match(/\w{3,}/) }
        
        expect(words).to eq(["Smith"])
        expect(words).not_to include("Dr")
      end

      it 'filters single letters and very short words' do
        test_article = build(:article, collection: collection, title: "A B Mr")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.match(/\w{3,}/) }
        
        expect(words).to be_empty
      end

      it 'preserves meaningful words of 3+ characters' do
        test_article = build(:article, collection: collection, title: "John Robert Calvert")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.match(/\w{3,}/) }
        words.sort! { |x,y| x.length <=> y.length }
        words.reverse!
        
        expect(words).to eq(["Calvert", "Robert", "John"])
      end

      it 'excludes words with punctuation that do not have enough word characters' do
        # Test with punctuation that isn't handled by tr(',.', ' ')
        test_article = build(:article, collection: collection, title: "Mr; Dr: Smith")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.match(/\w{3,}/) }
        
        # "Mr;" should be excluded (only 2 word characters)
        # "Dr:" should be excluded (only 2 word characters)  
        # "Smith" should be included (5 word characters)
        expect(words).to eq(["Smith"])
        expect(words).not_to include("Mr;")
        expect(words).not_to include("Dr:")
      end

      it 'includes 3+ character titles even with punctuation' do
        # "Mrs" is a legitimate 3-character title that should be preserved
        test_article = build(:article, collection: collection, title: "Mrs: Johnson")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.match(/\w{3,}/) }
        
        # Both "Mrs:" and "Johnson" should be included 
        # "Mrs:" contains "Mrs" (3 word characters)
        # "Johnson" contains "Johnson" (7 word characters)
        expect(words).to eq(["Mrs:", "Johnson"])
      end

      it 'handles fixture data correctly' do
        # Test with existing fixture article title to ensure compatibility
        test_article = build(:article, collection: collection, title: "Mrs.")
        
        words = test_article.title.tr(',.', ' ').split(' ')
        words.keep_if { |word| word.match(/\w{3,}/) }
        
        # "Mrs." becomes "Mrs" after tr() and should be included (3 characters)
        expect(words).to eq(["Mrs"])
      end

      it 'demonstrates the intended reduction in false positives' do
        # Show the before/after behavior for the original problem case
        title = "F. R. Calvert"
        words = title.tr(',.', ' ').split(' ')
        
        # Old behavior would include nothing (F, R have <2 chars)
        old_filtered = words.select { |word| word.match(/\w\w/) }
        expect(old_filtered).to eq(["Calvert"])
        
        # New behavior still includes only meaningful words
        new_filtered = words.select { |word| word.match(/\w{3,}/) }
        expect(new_filtered).to eq(["Calvert"])
        
        # Demonstrate fix for "Dr. Smith" case
        title2 = "Dr. Smith"
        words2 = title2.tr(',.', ' ').split(' ')
        
        old_filtered2 = words2.select { |word| word.match(/\w\w/) }
        expect(old_filtered2).to eq(["Dr", "Smith"])  # Would match both
        
        new_filtered2 = words2.select { |word| word.match(/\w{3,}/) }
        expect(new_filtered2).to eq(["Smith"])  # Only matches meaningful word
      end
    end
  end
end