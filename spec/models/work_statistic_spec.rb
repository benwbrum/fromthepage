require 'spec_helper'

RSpec.describe WorkStatistic, type: :model do
  context 'WorkStatistic initialization' do
    let(:work) { create(:work) }
    it 'New works set initial stats to zero' do
      stats = work.work_statistic
      # Total Pages
      expect(stats.total_pages).to eq(0)
      # Transcription Stats
      expect(stats.transcribed_pages).to eq(0)
      expect(stats.blank_pages).to eq(0)
      expect(stats.annotated_pages).to eq(0)
      expect(stats.needs_review).to eq(0)
      expect(stats.complete).to eq(0)
      # OCR Stats
      expect(stats.corrected_pages).to eq(0)
      # Translation Stats
      expect(stats.translated_pages).to eq(0)
      expect(stats.translated_blank).to eq(0)
      expect(stats.translated_annotated).to eq(0)
      expect(stats.translated_review).to eq(0)
      expect(stats.translation_complete).to eq(0)
    end
  end
  context 'computed attributes/method' do
    let(:ws) { build_stubbed(:work_statistic) }
    describe '#pct_transcribed' do
      it 'returns 0 for 0/3 pages transcribed' do
        ws.total_pages = 3
        ws.transcribed_pages = 0
        expect(ws.pct_transcribed).to eq(0)
      end
      it 'returns 33.33% for 1/3 pages transcribed' do
        ws.total_pages = 3
        ws.transcribed_pages = 1
        expect(ws.pct_transcribed).to eq(33.33)
      end
      it 'returns 100% for 3/3 pages transcribed' do
        ws.total_pages = 3
        ws.transcribed_pages = 3
        expect(ws.pct_transcribed).to eq(100)
      end
    end
    describe '#pct_corrected' do
      it 'returns 0 for 0/3 pages OCR Corrected' do
        ws.total_pages = 3
        ws.corrected_pages = 0
        expect(ws.pct_corrected).to eq(0)
      end
      it 'returns 33.33% for 1/3 pages OCR Corrected' do
        ws.total_pages = 3
        ws.corrected_pages = 1
        expect(ws.pct_corrected).to eq(33.33)
      end
      it 'returns 100% for 3/3 pages OCR Corrected' do
        ws.total_pages = 3
        ws.corrected_pages = 3
        expect(ws.pct_corrected).to eq(100)
      end
    end
    describe '#pct_translated' do
      it 'returns 0 for 0/3 pages translated' do
        ws.total_pages = 3
        ws.translated_pages = 0
        expect(ws.pct_translated).to eq(0)
      end
      it 'returns 33.33% for 1/3 pages translated' do
        ws.total_pages = 3
        ws.translated_pages = 1
        expect(ws.pct_translated).to eq(33.33)
      end
      it 'returns 100% for 3/3 pages translated' do
        ws.total_pages = 3
        ws.translated_pages = 3
        expect(ws.pct_translated).to eq(100)
      end
    end
    describe '#pct_annotated' do
      it 'returns 0 for 0/3 pages annotated' do
        ws.total_pages = 3
        ws.annotated_pages = 0
        expect(ws.pct_annotated).to eq(0)
      end
      it 'returns 33.33% for 1/3 pages annotated' do
        ws.total_pages = 3
        ws.annotated_pages = 1
        expect(ws.pct_annotated).to eq(33.33)
      end
      it 'returns 100% for 3/3 pages annotated' do
        ws.total_pages = 3
        ws.annotated_pages = 3
        expect(ws.pct_annotated).to eq(100)
      end
    end
    describe '#pct_translation_annotated' do
      it 'returns 0 for 0/3 translations annotated' do
        ws.total_pages = 3
        ws.translated_annotated = 0
        expect(ws.pct_translation_annotated).to eq(0)
      end
      it 'returns 33.33% for 1/3 translations annotated' do
        ws.total_pages = 3
        ws.translated_annotated = 1
        expect(ws.pct_translation_annotated).to eq(33.33)
      end
      it 'returns 100% for 3/3 translations annotated' do
        ws.total_pages = 3
        ws.translated_annotated = 3
        expect(ws.pct_translation_annotated).to eq(100)
      end
    end
    describe '#pct_needs_review' do
      it 'returns 0 for 0/3 pages need review' do
        ws.total_pages = 3
        ws.needs_review = 0
        expect(ws.pct_needs_review).to eq(0)
      end
      it 'returns 33.33% for 1/3 pages need review' do
        ws.total_pages = 3
        ws.needs_review = 1
        expect(ws.pct_needs_review).to eq(33.33)
      end
      it 'returns 100% for 3/3 pages need review' do
        ws.total_pages = 3
        ws.needs_review = 3
        expect(ws.pct_needs_review).to eq(100)
      end
    end
    describe '#pct_translation_needs_review' do
      it 'returns 0 for 0/3 translations needing review' do
        ws.total_pages = 3
        ws.translated_review = 0
        expect(ws.pct_translation_needs_review).to eq(0)
      end
      it 'returns 33.33% for 1/3 translations needing review' do
        ws.total_pages = 3
        ws.translated_review = 1
        expect(ws.pct_translation_needs_review).to eq(33.33)
      end
      it 'returns 100% for 3/3 translations needing review' do
        ws.total_pages = 3
        ws.translated_review = 3
        expect(ws.pct_translation_needs_review).to eq(100)
      end
    end
    describe '#pct_blank' do
      it 'returns 0 for 0/3 blank pages' do
        ws.total_pages = 3
        ws.blank_pages = 0
        expect(ws.pct_blank).to eq(0)
      end
      it 'returns 33.33% for 1/3 blank pages' do
        ws.total_pages = 3
        ws.blank_pages = 1
        expect(ws.pct_blank).to eq(33.33)
      end
      it 'returns 100% for 3/3 blank pages' do
        ws.total_pages = 3
        ws.blank_pages = 3
        expect(ws.pct_blank).to eq(100)
      end
    end
    describe '#pct_translation_blank' do
      it 'returns 0 for 0/3 blank translations' do
        ws.total_pages = 3
        ws.translated_blank = 0
        expect(ws.pct_translation_blank).to eq(0)
      end
      it 'returns 33.33% for 1/3 blank translations' do
        ws.total_pages = 3
        ws.translated_blank = 1
        expect(ws.pct_translation_blank).to eq(33.33)
      end
      it 'returns 100% for 3/3 blank translations' do
        ws.total_pages = 3
        ws.translated_blank = 3
        expect(ws.pct_translation_blank).to eq(100)
      end
    end
    describe '#pct_transcribed_or_blank' do
      it 'returns 0 for 0/3 translated or blank' do
        ws.total_pages = 3
        ws.blank_pages = 0
        ws.transcribed_pages = 0
        expect(ws.pct_transcribed_or_blank).to eq(0)
      end
      it 'returns 66.66% for (2/3) one blank and one transcribed' do
        ws.total_pages = 3
        ws.blank_pages = 1
        ws.transcribed_pages = 1
        expect(ws.pct_transcribed_or_blank).to eq(66.66)
      end
      it 'returns 100% for (3/3) one blank and two transcribed' do
        ws.total_pages = 3
        ws.blank_pages = 1
        ws.transcribed_pages = 2
        expect(ws.pct_transcribed_or_blank).to eq(100)
      end
    end
    describe '#pct_translated_or_blank' do
      it 'returns 0 for 0/3 none translated or blank' do
        ws.total_pages = 3
        ws.blank_pages = 0
        ws.translated_pages = 0
        expect(ws.pct_translated_or_blank).to eq(0)
      end
      it 'returns 66.66% for (2/3) one translated and one translated_blank' do
        ws.total_pages = 3
        ws.translated_blank = 1
        ws.translated_pages = 1
        expect(ws.pct_translated_or_blank).to eq(66.66)
      end
      it 'returns 100% for 3/3 XXX' do
        ws.total_pages = 3
        ws.translated_blank = 1
        ws.translated_pages = 2
        expect(ws.pct_translated_or_blank).to eq(100)
      end
    end
    describe '#pct_completed' do
      let(:work_ocr) { build_stubbed(:work, ocr_correction: true) }

      context 'OCR Disabled' do
        let(:work) { build_stubbed(:work, ocr_correction: false) }

        it 'returns 0 for 0/3 nothing done, no OCR' do
          ws.work = work
          ws.total_pages = 3
          ws.transcribed_pages = 0
          ws.annotated_pages = 0

          expect(ws.pct_completed).to eq(0)
        end
        it 'returns 66.66% for 2/3 complete' do
          ws.work = work
          ws.total_pages = 3
          ws.transcribed_pages = 1
          ws.annotated_pages = 1

          expect(ws.pct_completed).to eq(66.66)
        end
        it 'returns 100% for 3/3 complete' do
          ws.work = work
          ws.total_pages = 3
          ws.transcribed_pages = 1
          ws.annotated_pages = 2

          expect(ws.pct_completed).to eq(100)
        end
      end
      context 'OCR Enabled' do
        let(:work) { build_stubbed(:work, ocr_correction: true) }

        it 'returns 0 for 0/3 nothing done' do
          ws.work = work
          ws.total_pages = 3
          ws.corrected_pages = 0
          ws.annotated_pages = 0

          expect(ws.pct_completed).to eq(0)
        end
        it 'returns 66.66% for 2/3 complete' do
          ws.work = work
          ws.total_pages = 3
          ws.corrected_pages = 1
          ws.annotated_pages = 1

          expect(ws.pct_completed).to eq(66.66)
        end
        it 'returns 100% for 3/3 complete' do
          ws.work = work
          ws.total_pages = 3
          ws.corrected_pages = 1
          ws.annotated_pages = 2

          expect(ws.pct_completed).to eq(100)
        end
      end
    end
    describe '#pct_translation_completed' do
      it 'returns 0 for 0/3 XXX translation completed' do
        ws.total_pages = 3
        ws.translated_pages = 0
        ws.translated_annotated = 0
        expect(ws.pct_translation_completed).to eq(0)
      end
      it 'returns 66.66% for 2/3 translation completed' do
        ws.total_pages = 3
        ws.translated_pages = 1
        ws.translated_annotated = 1
        expect(ws.pct_translation_completed).to eq(66.66)
      end
      it 'returns 100% for 3/3 XXX translation completed' do
        ws.total_pages = 3
        ws.translated_pages = 2
        ws.translated_annotated = 1
        expect(ws.pct_translation_completed).to eq(100)
      end
    end
  end
  context 'update methods' do
    let(:work) { create(:work) }
    let(:ws) do
      create(:work_statistic, work: work)
    end

    describe '#recalculate' do
      before :each do
        # Stubb for Flag-checking pages
        allow(Flag).to receive(:check_page)
      end
      it 'recalculates without params' do
        ws.recalculate
      end
      it 'recalculates with all page status types' do
        # Ensures compatibility with old API
        Page.statuses.each_value do |status|
          ws.recalculate(type: status)
        end
      end
      context 'transcription stats' do
        it 'updates total pages' do
          ws.recalculate
          expect(ws.total_pages).to eq(0)

          create(:page, work: work)
          ws.recalculate
          expect(ws.total_pages).to eq(1)
        end
        it 'updates transcribed_pages' do
          ws.recalculate
          expect(ws.transcribed_pages).to eq(0)

          create(:page, work: work, status: :transcribed)
          ws.recalculate
          expect(ws.transcribed_pages).to eq(1)
        end
        it 'updates blank_pages' do
          ws.recalculate
          expect(ws.blank_pages).to eq(0)

          create(:page, work: work, status: :blank)
          ws.recalculate
          expect(ws.blank_pages).to eq(1)
        end
        it 'updates annotated_pages' do
          ws.recalculate
          expect(ws.annotated_pages).to eq(0)

          create(:page, work: work, status: :indexed)
          ws.recalculate
          expect(ws.annotated_pages).to eq(1)
        end
        it 'updates needs_review' do
          ws.recalculate
          expect(ws.needs_review).to eq(0)

          create(:page, work: work, status: :needs_review)
          ws.recalculate
          expect(ws.needs_review).to eq(1)
        end
        context 'with OCR diabled (default)' do
          it 'updates complete' do
            ws.recalculate
            expect(ws.complete).to eq(0)

            create(:page, work: work, status: :transcribed)
            create(:page, work: work, status: :blank)
            create(:page, work: work, status: :indexed)
            create(:page, work: work, status: :needs_review)
            ws.recalculate

            # Corrected and Transcribed are synonymous and
            # should always equal the same value
            expect(ws.transcribed_pages).to eq(1)
            expect(ws.corrected_pages).to eq(1)
            expect(ws.complete).to eq(75)
          end
        end
        context 'with OCR enabled' do
          let(:work) { create(:work, ocr_correction: true) }
          let(:ws) do
            create(:work_statistic,
                   work: work)
          end

          it 'updates complete' do
            ws.recalculate
            expect(ws.complete).to eq(0)

            create(:page, work: work, status: :transcribed)
            create(:page, work: work, status: :blank)
            create(:page, work: work, status: :blank)
            create(:page, work: work, status: :indexed)
            create(:page, work: work, status: :needs_review)
            ws.recalculate

            # Corrected and Transcribed are synonymous and
            # should always equal the same value
            expect(ws.transcribed_pages).to eq(1)
            expect(ws.corrected_pages).to eq(1)
            expect(ws.complete).to eq(80)
          end
        end
      end
      context 'translation stats' do
        it 'updates translated_pages' do
          ws.recalculate
          expect(ws.translated_pages).to eq(0)

          create(:page, work: work, translation_status: :translated)
          ws.recalculate
          expect(ws.translated_pages).to eq(1)
        end
        it 'updates translated_blank' do
          ws.recalculate
          expect(ws.translated_blank).to eq(0)

          create(:page, work: work, translation_status: :blank)
          ws.recalculate
          expect(ws.translated_blank).to eq(1)
        end
        it 'updates translated_annotated' do
          ws.recalculate
          expect(ws.translated_annotated).to eq(0)

          create(:page, work: work, translation_status: :indexed)
          ws.recalculate
          expect(ws.translated_annotated).to eq(1)
        end
        it 'updates translated_review' do
          ws.recalculate
          expect(ws.translated_review).to eq(0)

          create(:page, work: work, translation_status: :needs_review)
          ws.recalculate
          expect(ws.translated_review).to eq(1)
        end
        it 'updates translation_complete' do
          ws.recalculate
          expect(ws.translation_complete).to eq(0)

          create(:page, work: work, translation_status: :translated)
          create(:page, work: work, translation_status: :blank)
          create(:page, work: work, translation_status: :indexed)
          create(:page, work: work, translation_status: :needs_review)
          ws.recalculate

          expect(ws.translation_complete).to eq(75)
        end
      end
    end
  end
end
