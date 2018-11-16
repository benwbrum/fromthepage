# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CollectionStatistic, type: :module do
  before :each do
    @user = create(:user)
    @collection = create(:collection, owner_user_id: @user.id)
  end

  after :each do
    @collection.destroy
    @user.destroy
  end

  describe '#work_count' do
    it "returns a count of a collection's works" do
      create(:work, collection_id: @collection.id)
      expect(@collection.work_count).to eq(1)
    end
  end

  describe '#page_count' do
    it "returns a count of the collection's work's pages" do
      work = create(:work, collection_id: @collection.id)
      page = create(:page, work_id: work.id)

      expect(@collection.page_count).to eq(1)
    end
  end

  describe 'within the X past days' do
    let(:last_days) { 7 }

    describe '#subject_count' do
      it "returns a count of the collection's articles" do
        article = create(:article, collection_id: @collection.id)
        expect(@collection.subject_count(last_days)).to eq(1)

        # Tear down factory objects
        article.destroy
      end
    end

    describe '#mention_count' do
      it "returns a count of page_article_links made in this collection" do
        work = create(:work, collection_id: @collection.id)
        page = create(:page, work_id: work.id)
        article = create(:article, collection_id: @collection.id)
        page_article_link = create(:page_article_link, page_id: page.id, article_id: article.id)

        expect(@collection.mention_count(last_days)).to eq(1)
        # Tear down factory objects
        page_article_link.destroy
        article.destroy
        page.destroy
        work.destroy
      end
    end

    describe '#contributor_count' do
      it "returns a count of users who contributed to any of this collection's works" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSCRIPTION
        )
        expect(@collection.contributor_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#comment_count' do
      it "returns a count of deeds for this collection where comments/notes were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::NOTE_ADDED
        )
        expect(@collection.comment_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#transcription_count' do
      it "returns a count of deeds for this collection where transcriptions were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSCRIPTION
        )
        expect(@collection.transcription_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#edit_count' do
      it "returns a count of deeds for this collection where pages were edited" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_EDIT
        )
        expect(@collection.edit_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#index_count' do
      it "returns a count of deeds for this collection where pages were indexed" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_INDEXED
        )
        expect(@collection.index_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#translation_count' do
      it "returns a count of deeds for this collection where translations were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSLATED
        )
        expect(@collection.translation_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#ocr_count' do
      it "returns a count of deeds for this collection where ocr corrections were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::OCR_CORRECTED
        )
        expect(@collection.ocr_count(last_days)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end
  end


  describe '#get_stats_hash' do
    xit "returns hash of...?" do
    end
  end

  describe '#calculate_complete' do
    it "when a collection has no works, it updates the collection.ptc_completed with 0" do
      @collection.calculate_complete
      expect(@collection.pct_completed).to eq(0)
    end

    it "when a collection has 1 of 2 works completed, it updates the collection.ptc_completed with 50" do
      work1 = create(:work, collection_id: @collection.id)
      work2 = create(:work, collection_id: @collection.id)
      page2a = create(:page, work_id: work2.id, status: Page::STATUS_TRANSCRIBED)
      @collection.calculate_complete

      expect(@collection.pct_completed).to eq(50)
    end

    it "when a collection has 1 of 1 works completed, it updates the collection.ptc_completed with 100" do
      work1 = create(:work, collection_id: @collection.id)
      page1 = create(:page, work_id: work1.id, status: Page::STATUS_TRANSCRIBED)
      @collection.calculate_complete

      expect(@collection.pct_completed).to eq(100)
    end
  end

end
