require 'spec_helper'

describe AiAccuracyCalculator do
  before do
    Current.user = owner
  end

  let!(:owner) { create(:unique_user, :owner) }
  let!(:collection) { create(:collection, owner_user_id: owner.id) }
  let!(:work) { create(:work, collection: collection) }
  let!(:page) { create(:page, work: work, status: status) }
  let!(:ai_transcription) { create(:ai_transcription, page: page, status: :finished) }

  let(:status) { :new }

  describe '#can_calculate_ai_accuracy?' do
    context 'when page has AI plaintext and human transcription' do
      let(:status) { :transcribed }
      let!(:page) do
        create(:page, work: work, status: status,
          xml_text: "<?xml version='1.0' encoding='UTF-8'?>\n<page>\n<p>Some human transcription</p>\n</page>"
        )
      end

      it 'returns true' do
        expect(page.can_calculate_ai_accuracy?).to be true
      end
    end

    context 'when page has AI plaintext and human transcription regardless of status' do
      let(:status) { :incomplete }
      let!(:page) do
        create(:page, work: work, status: status,
          xml_text: "<?xml version='1.0' encoding='UTF-8'?>\n<page>\n<p>Some human transcription</p>\n</page>"
        )
      end

      it 'returns true' do
        expect(page.can_calculate_ai_accuracy?).to be true
      end
    end

    context 'when page has AI plaintext but no human transcription' do
      let(:status) { :incomplete }

      it 'returns false' do
        expect(page.can_calculate_ai_accuracy?).to be false
      end
    end

    context 'when page has human transcription but no AI plaintext' do
      let(:ai_transcription) { nil }
      let(:status) { :transcribed }
      let!(:page) do
        create(:page, work: work, status: status,
          xml_text: "<?xml version='1.0' encoding='UTF-8'?>\n<page>\n<p>Some human transcription</p>\n</page>"
        )
      end

      it 'returns false' do
        expect(page.can_calculate_ai_accuracy?).to be false
      end
    end
  end

  describe '#ai_accuracy_statistics' do
    context 'when statistics can be calculated' do
      let(:status) { :transcribed }
      let!(:page) do
        create(:page, work: work, status: status,
          source_text: '<page><p>Hello world, this is a test.</p></page>',
          xml_text: "<?xml version='1.0' encoding='UTF-8'?>\n<page>\n<p><page><p>Hello world, this is a test.</p></page></p>\n</page>"
        )
      end
      let!(:ai_transcription) { create(:ai_transcription, page: page, source_text: 'Hello world, this is a test.', status: :finished) }

      it 'returns a hash with verbatim and text_only statistics' do
        stats = page.ai_accuracy_statistics

        expect(stats).to be_a(Hash)
        expect(stats).to have_key(:verbatim)
        expect(stats).to have_key(:text_only)
      end

      it 'includes CER and WER in verbatim stats' do
        stats = page.ai_accuracy_statistics

        expect(stats[:verbatim]).to have_key(:cer)
        expect(stats[:verbatim]).to have_key(:wer)
      end

      it 'includes non-stopword accuracy if language is supported' do
        # modify the collection's text language to be English
        allow(page).to receive(:collection).and_return(double(text_language: 'eng', field_based: false))
        stats = page.ai_accuracy_statistics

        expect(stats[:verbatim]).to have_key(:non_stopword_accuracy)
      end

      it 'does not include non-stopword accuracy if language is unsupported' do
        # modify the collection's text language to be Akkadian
        allow(page).to receive(:collection).and_return(double(text_language: 'akk', field_based: false))
        stats = page.ai_accuracy_statistics

        expect(stats[:verbatim]).not_to have_key(:non_stopword_accuracy)
      end

      it 'includes CER and WER in text_only stats' do
        stats = page.ai_accuracy_statistics

        expect(stats[:text_only]).to have_key(:cer)
        expect(stats[:text_only]).to have_key(:wer)
      end
    end

    context 'when statistics cannot be calculated' do
      let(:status) { :incomplete }

      it 'returns nil when no human transcription exists' do
        expect(page.ai_accuracy_statistics).to be_nil
      end
    end
  end

  describe 'accuracy calculation methods' do
    describe '#character_error_rate' do
      it 'returns 0 for identical strings' do
        cer = page.send(:character_error_rate, 'hello', 'hello')
        expect(cer).to eq(0.0)
      end

      it 'returns 100 for completely different strings of same length' do
        cer = page.send(:character_error_rate, 'abc', 'xyz')
        expect(cer).to eq(100.0)
      end

      it 'returns 100 for completely different strings with longer ground truth' do
        cer = page.send(:character_error_rate, 'abcd', 'xy')
        expect(cer).to eq(100.0)
      end

      it 'calculates CER correctly for similar strings' do
        cer = page.send(:character_error_rate, 'abcd', 'abxy')
        expect(cer).to eq(50.0)
      end

      it 'handles empty ground truth' do
        cer = page.send(:character_error_rate, '', 'hello')
        expect(cer).to eq(100.0)
      end

      it 'handles empty predicted text' do
        cer = page.send(:character_error_rate, 'hello', '')
        expect(cer).to eq(100.0)
      end
    end

    describe '#word_error_rate' do
      it 'returns 0 for identical word sequences' do
        wer = page.send(:word_error_rate, 'hello world', 'hello world')
        expect(wer).to eq(0.0)
      end

      it 'calculates WER for different word sequences' do
        wer = page.send(:word_error_rate, 'the cat sat', 'the dog sat')
        expect(wer).to be > 0
        expect(wer).to be <= 100
      end

      it 'handles single word differences' do
        wer = page.send(:word_error_rate, 'hello world test', 'hello world testing')
        expect(wer).to be > 0
      end

      it 'handles empty ground truth' do
        wer = page.send(:word_error_rate, '', 'hello world')
        expect(wer).to eq(100.0)
      end

      it 'handles empty predicted text' do
        wer = page.send(:word_error_rate, 'hello world', '')
        expect(wer).to eq(100.0)
      end
    end

    describe '#non_stopword_accuracy' do
      before do
        # Mock collection with English language for consistency
        allow(page).to receive(:collection).and_return(double(text_language: 'eng'))
      end

      it 'returns 100 for identical content words' do
        accuracy = page.send(:non_stopword_accuracy, 'the cat jumped', 'the cat jumped')
        expect(accuracy).to eq(100.0)
      end

      it 'ignores stopwords in comparison' do
        # Both texts should have same non-stopwords after filtering
        accuracy = page.send(:non_stopword_accuracy, 'a cat jumped', 'the cat jumped')
        expect(accuracy).to eq(100.0)
      end

      it 'calculates accuracy based on content words' do
        # With stopwords filtered, should measure overlap of content words
        accuracy = page.send(:non_stopword_accuracy, 'the cat jumped', 'the dog jumped')
        # Expect 50% since one of two content words matches
        expect(accuracy).to eq(50.0)
      end

      it 'handles text with only stopwords' do
        accuracy = page.send(:non_stopword_accuracy, 'the a is', 'the a was')
        # All stopwords filtered out, both empty
        expect(accuracy).to eq(100.0)
      end

      it 'handles empty text' do
        accuracy = page.send(:non_stopword_accuracy, '', '')
        expect(accuracy).to eq(100.0)
      end

      it 'handles repeated non-stopwords' do
        # "cat" appears twice in both, should count both occurrences but miss the verb for 2/3 accuracy
        accuracy = page.send(:non_stopword_accuracy, 'a cat hopped over the cat', 'the cat jumped under a cat')
        expect(accuracy).to eq(66.67)
      end
    end

    describe '#normalize_text' do
      it 'removes punctuation' do
        normalized = page.send(:normalize_text, 'Hello, world!')
        expect(normalized).to eq('hello world')
      end

      it 'converts to lowercase' do
        normalized = page.send(:normalize_text, 'Hello World')
        expect(normalized).to eq('hello world')
      end

      it 'collapses multiple spaces' do
        normalized = page.send(:normalize_text, 'hello    world')
        expect(normalized).to eq('hello world')
      end

      it 'trims whitespace' do
        normalized = page.send(:normalize_text, '  hello world  ')
        expect(normalized).to eq('hello world')
      end

      it 'handles newlines' do
        normalized = page.send(:normalize_text, "hello\nworld")
        expect(normalized).to eq('hello world')
      end

      it 'handles empty text' do
        normalized = page.send(:normalize_text, '')
        expect(normalized).to eq('')
      end

      it 'combines all normalizations' do
        normalized = page.send(:normalize_text, '  Hello,   WORLD!  ')
        expect(normalized).to eq('hello world')
      end
    end

    describe '#extract_non_stopwords' do
      before do
        # Mock collection with English language
        allow(page).to receive(:collection).and_return(double(text_language: 'en'))
      end

      it 'extracts content words' do
        words = page.send(:extract_non_stopwords, 'The cat jumped over the fence')
        # With stopwords-filter, common words like 'the', 'over' will be filtered
        expect(words).to include('cat', 'jumped', 'fence')
      end

      it 'removes stopwords' do
        words = page.send(:extract_non_stopwords, 'this is a test')
        expect(words).to include('test')
        # Common stopwords should be filtered out
        expect(words).not_to include('this', 'is', 'a')
      end

      it 'handles punctuation' do
        words = page.send(:extract_non_stopwords, 'Hello, world!')
        expect(words).to include('hello', 'world')
      end

      it 'handles empty text' do
        words = page.send(:extract_non_stopwords, '')
        expect(words).to eq([])
      end

      it 'returns empty array when collection has no language' do
        allow(page).to receive(:collection).and_return(double(text_language: nil))
        words = page.send(:extract_non_stopwords, 'Hello world')
        expect(words).to eq([])
      end
    end
  end

  describe 'integration test with real page data' do
    let(:status) { :transcribed }
    let!(:page) do
      create(:page, work: work, status: status,
        source_text: '<page><p>The quick brown fox jumps over the lazy dog.</p></page>',
        xml_text: "<?xml version='1.0' encoding='UTF-8'?>\n<page>\n<p><page><p>The quick brown fox jumps over the lazy dog.</p></page></p>\n</page>"
      )
    end
    let!(:ai_transcription) do
      create(:ai_transcription, page: page, source_text: 'The quick brown fox jumped over the lazy dog.', status: :finished)
    end

    it 'calculates statistics for similar texts' do
      stats = page.ai_accuracy_statistics

      expect(stats).not_to be_nil
      expect(stats[:verbatim][:cer]).to be < 20.0
      expect(stats[:verbatim][:wer]).to be < 20.0
      # Non-stopword accuracy may or may not be present depending on language support
    end
  end
end
