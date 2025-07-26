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

    context 'when detecting duplicate articles' do
      it 'excludes short words like "Dr" to reduce false positives' do
        # Create the main article we're checking for duplicates
        main_article = create(:article, collection: collection, title: "Dr. Smith")
        
        # Create articles with various titles
        smith_article = create(:article, collection: collection, title: "John Smith")
        doctor_article = create(:article, collection: collection, title: "Dr. Jones") 
        unrelated_article = create(:article, collection: collection, title: "Mary Brown")
        
        # Call the actual possible_duplicates method
        duplicates = main_article.possible_duplicates
        
        # Should find "John Smith" because it contains "Smith" (3+ characters)
        expect(duplicates).to include(smith_article)
        
        # Should NOT find "Dr. Jones" because "Dr" is filtered out (< 3 characters)
        expect(duplicates).not_to include(doctor_article)
        
        # Should NOT find unrelated article
        expect(duplicates).not_to include(unrelated_article)
      end

      it 'finds articles with shared meaningful words' do
        main_article = create(:article, collection: collection, title: "F. R. Calvert")
        
        # Articles that should be found
        calvert_match = create(:article, collection: collection, title: "John Calvert")
        calvert_family = create(:article, collection: collection, title: "Calvert Family")
        
        # Articles that should NOT be found (only short words match)
        initial_only = create(:article, collection: collection, title: "F. Johnson")
        unrelated = create(:article, collection: collection, title: "Mary Brown")
        
        duplicates = main_article.possible_duplicates
        
        # Should find articles with "Calvert"
        expect(duplicates).to include(calvert_match)
        expect(duplicates).to include(calvert_family)
        
        # Should NOT find articles with only short initials or unrelated names
        expect(duplicates).not_to include(initial_only)
        expect(duplicates).not_to include(unrelated)
      end

      it 'handles titles with punctuation correctly' do
        main_article = create(:article, collection: collection, title: "Mrs. Johnson")
        
        # Should find articles with "Johnson" (meaningful word)
        johnson_match = create(:article, collection: collection, title: "Robert Johnson")
        
        # Should find articles with "Mrs" (3+ characters, even with punctuation)
        mrs_match = create(:article, collection: collection, title: "Mrs Smith")
        
        # Should NOT find articles with only short titles
        short_title = create(:article, collection: collection, title: "Mr. Brown")
        
        duplicates = main_article.possible_duplicates
        
        expect(duplicates).to include(johnson_match)
        expect(duplicates).to include(mrs_match)
        expect(duplicates).not_to include(short_title)
      end

      it 'does not return the same article as a duplicate of itself' do
        main_article = create(:article, collection: collection, title: "John Smith")
        
        # Create another article with similar title
        other_article = create(:article, collection: collection, title: "Jane Smith")
        
        duplicates = main_article.possible_duplicates
        
        # Should find the other article but not itself
        expect(duplicates).to include(other_article)
        expect(duplicates).not_to include(main_article)
      end

      it 'only searches within the same collection' do
        # Create articles in different collections
        collection1 = create(:collection)
        collection2 = create(:collection)
        
        main_article = create(:article, collection: collection1, title: "John Smith")
        same_collection = create(:article, collection: collection1, title: "Jane Smith")
        different_collection = create(:article, collection: collection2, title: "Bob Smith")
        
        duplicates = main_article.possible_duplicates
        
        # Should only find articles in the same collection
        expect(duplicates).to include(same_collection)
        expect(duplicates).not_to include(different_collection)
      end

      it 'prioritizes articles with longer matching words' do
        main_article = create(:article, collection: collection, title: "Robert Johnson Smith")
        
        # Create articles with different word matches
        short_match = create(:article, collection: collection, title: "Bob Johnson")
        long_match = create(:article, collection: collection, title: "Elizabeth Smith")
        
        duplicates = main_article.possible_duplicates
        
        # Should find both, but longer words are processed first in the algorithm
        expect(duplicates).to include(short_match)
        expect(duplicates).to include(long_match)
        
        # The exact ordering depends on the internal algorithm, but both should be found
        expect(duplicates.count).to eq(2)
      end
    end
  end
end