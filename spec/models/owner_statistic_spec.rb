# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OwnerStatistic, type: :module do
  before :each do
    @owner = create(:user)
    @collection = create(:collection, owner_user_id: @owner.id)
  end

  after :each do
    @collection.destroy
    @owner.destroy
  end

  describe '#work_count' do
    it "returns a count of a collection owner's works" do
      work = create(:work, collection_id: @collection.id)
      expect(@owner.work_count).to eq(1)
    end

    it "does not count the works in other user's collections" do
      user2 = create(:user)
      collection2 = create(:collection, owner_user_id: user2)
      work2 = create(:work, collection_id: collection2.id)

      expect(@owner.work_count).to eq(0)

      # Tear down factory objects
      collection2.destroy
      user2.destroy
    end
  end

  describe '#completed_work_count' do
    it "returns 0 when a user has no works" do
      expect(@owner.completed_work_count).to eq(0)
    end

    it "returns 1 when an owner has 1 of 2 works completed" do
      work1 = create(:work, collection_id: @collection.id)
      work2 = create(:work, collection_id: @collection.id)
      page2a = create(:page, work_id: work2.id, status: Page::STATUS_TRANSCRIBED)

      expect(@owner.completed_work_count).to eq(1)

      # Tear down factory objects
      page2a.destroy
      work2.destroy
      work1.destroy
    end
  end

  describe '#page_count' do
    it "returns a count of the user's page_count collections" do
      work = create(:work, collection_id: @collection.id)
      page = create(:page, work_id: work.id)

      expect(@owner.page_count).to eq(1)

      # Tear down factory objects
      work.destroy
    end
  end

  describe '#owner_subjects' do
    it "returns all articles related to a collection owned by the user" do
      article = create(:article, collection_id: @collection.id)
      expect(@owner.owner_subjects).to include(article)

      # Tear down factory objects
      article.destroy
    end

    it "does not return articles related to a collection not owned by the user" do
      user2 = create(:user)
      collection2 = create(:collection, owner_user_id: user2)
      article = create(:article, collection_id: collection2.id)

      expect(@owner.owner_subjects).not_to include(article)

      # Tear down factory objects
      article.destroy
      user2.destroy
    end
  end

  describe '#collection_ids' do
    it "returns ids of all of the collections owned by this user" do
      expect(@owner.collection_ids).to include(@collection.id)
    end

    it "does not return ids of collections owned by other users" do
      user2 = create(:user)
      collection2 = create(:collection, owner_user_id: user2)

      expect(@owner.collection_ids).not_to include(collection2.id)

      # Tear down factory objects
      user2.destroy
    end
  end

  context 'within a date range' do
    let(:start_date) { '2018-09-30' }
    let(:end_date) { '2018-10-30' }

    describe '#subject_count' do
      it "returns a count of articles created in the user's collections" do
        article = create(:article, collection_id: @collection.id, created_on: start_date)
        expect(@owner.subject_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        article.destroy
      end
    end

    describe '#mention_count' do
      it "returns a count of page_article_links made in this user's collections" do
        work = create(:work, collection_id: @collection.id)
        page = create(:page, work_id: work.id)
        article = create(:article, collection_id: @collection.id)
        page_article_link = create(:page_article_link, page_id: page.id, article_id: article.id, created_on: start_date)

        expect(@owner.mention_count(start_date, end_date)).to eq(1)
        # Tear down factory objects
        page_article_link.destroy
        article.destroy
        page.destroy
        work.destroy
      end
    end

    describe '#contributor_count' do
      it "returns a count of users who contributed to any of the owner's collections" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSCRIPTION,
          created_at: start_date
        )
        expect(@owner.contributor_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#comment_count' do
      it "returns a count of deeds for the owner's collections where comments/notes were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::NOTE_ADDED,
          created_at: start_date
        )
        expect(@owner.comment_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#transcription_count' do
      it "returns a count of deeds for the owner's collections where comments/notes were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSCRIPTION,
          created_at: start_date
        )
        expect(@owner.transcription_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#edit_count' do
      it "returns a count of deeds for the owner's collections where pages were edited" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_EDIT,
          created_at: start_date
        )
        expect(@owner.edit_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#index_count' do
      it "returns a count of deeds for the owner's collections where pages were indexed" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_INDEXED,
          created_at: start_date
        )
        expect(@owner.index_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#translation_count' do
      it "returns a count of deeds for the owner's collections where translations were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::PAGE_TRANSLATED,
          created_at: start_date
        )
        expect(@owner.translation_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end

    describe '#ocr_count' do
      it "returns a count of deeds for the owner's collections where ocr corrections were made" do
        contributor = create(:user)
        contributor_deed = create(:deed,
          user_id: contributor.id,
          collection_id: @collection.id,
          deed_type: Deed::OCR_CORRECTED,
          created_at: start_date
        )
        expect(@owner.ocr_count(start_date, end_date)).to eq(1)

        # Tear down factory objects
        contributor_deed.destroy
        contributor.destroy
      end
    end
  end

  describe '#all_collaborators' do
    it "returns all users with deeds associated with this user's collections" do
      contributor = create(:user)
      contributor_deed = create(:deed,
        user_id: contributor.id,
        collection_id: @collection.id,
        deed_type: Deed::OCR_CORRECTED
      )
      expect(@owner.all_collaborators).to include(contributor)

      # Tear down factory objects
      contributor_deed.destroy
      contributor.destroy
    end

    it "does not include users with deeds associated with this other users' collections" do
      owner2 = create(:user)
      collection2 = create(:collection, owner_user_id: owner2)
      contributor = create(:user)
      contributor_deed = create(:deed,
        user_id: contributor.id,
        collection_id: collection2.id,
        deed_type: Deed::OCR_CORRECTED
      )
      expect(@owner.all_collaborators).not_to include(contributor)

      # Tear down factory objects
      contributor_deed.destroy
      contributor.destroy
      collection2.destroy
      owner2.destroy
    end
  end

  describe '#subjects_disabled' do
    it "always returns false" do
      user = build_stubbed(:user)
      expect(user.subjects_disabled).to be false
    end
  end
end
