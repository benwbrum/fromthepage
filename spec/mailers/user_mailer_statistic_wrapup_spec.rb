require 'spec_helper'

RSpec.describe UserMailer::StatisticWrapup do

  describe ".build" do
    before :all do
      @owner = create(:user, email: 'owner@example.com', login: 'owner')
      @contributor = create(:user, email: 'contributor@example.com', login: 'contributor')
      @start_date = '2018-10-31'
      @end_date = '2018-09-30'
    end

    after :all do
      @owner.destroy
      @contributor.destroy
    end

    context 'when the object is a user' do
      it "stores the owner as an attribute" do
        wrapup = UserMailer::StatisticWrapup.build(
          object: @owner,
          start_date: @start_date,
          end_date: @end_date
        )
        expect(wrapup.owner).to eq(@owner)
      end

      it "stores the completed_work_count as an attribute" do
        qty = 2
        allow(@owner).to receive(:completed_work_count).and_return(qty)

        wrapup = UserMailer::StatisticWrapup.build(
          object: @owner,
          start_date: @start_date,
          end_date: @end_date
        )
        expect(wrapup.completed_work_count).to eq(qty)
      end
    end

    context 'when the object is a collection' do
      it "stores the owner as an attribute" do
        collection = build_stubbed(:collection, owner_user_id: @owner.id)
        wrapup = UserMailer::StatisticWrapup.build(
          object: collection
        )
        expect(wrapup.owner).to eq(collection.owner)
      end

      it "stores the collection as an attribute" do
        collection = build_stubbed(:collection, owner_user_id: @owner.id)
        wrapup = UserMailer::StatisticWrapup.build(
          object: collection
        )
        expect(wrapup.collection).to eq(collection)
      end

      it "stores the collection title as an attribute" do
        collection = build_stubbed(:collection, owner_user_id: @owner.id)
        wrapup = UserMailer::StatisticWrapup.build(
          object: collection
        )
        expect(wrapup.title).to eq(collection.title)
      end
    end

    it "stores the contributors' emails as an attribute" do
      contributor = build(:user)
      contributor_email = "#{contributor.display_name} <#{contributor.email}>"
      allow(UserMailer::StatisticWrapup).to receive(:contributor_email_list).and_return(contributor_email)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.contributor_emails).to eq(contributor_email)
    end

    it "stores the contributor count as an attribute" do
      qty = 2
      allow(@owner).to receive(:contributor_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.contributor_count).to eq(qty)
    end

    it "stores the work count as an attribute" do
      qty = 2
      allow(@owner).to receive(:work_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.work_count).to eq(qty)
    end

    it "stores the page_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:page_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.page_count).to eq(qty)
    end

    it "stores the transcription_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:transcription_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.transcription_count).to eq(qty)
    end

    it "stores the edit_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:edit_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.edit_count).to eq(qty)
    end

    it "stores the translation_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:translation_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.translation_count).to eq(qty)
    end

    it "stores the ocr_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:ocr_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.ocr_count).to eq(qty)
    end

    it "stores the mention_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:mention_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.mention_count).to eq(qty)
    end

    it "stores the index_count as an attribute" do
      qty = 2
      allow(@owner).to receive(:index_count).and_return(qty)

      wrapup = UserMailer::StatisticWrapup.build(
        object: @owner,
        start_date: @start_date,
        end_date: @end_date
      )
      expect(wrapup.index_count).to eq(qty)
    end
  end


  describe '#translations?' do
    before :all do
     user = build_stubbed(:user)
     @wrapup = build(:statistic_wrapup, owner: user )
    end

    it 'returns true if a wrapup owner has translation contributions' do
      @wrapup.translation_count = 2
      expect(@wrapup.translations?).to be true
    end

    it 'returns false if a wrapup owner does not have translation contributions' do
      @wrapup.translation_count = 0
      expect(@wrapup.translations?).to be false
    end
  end

  describe '#ocr_corrections?' do
    before :all do
     user = build_stubbed(:user)
     @wrapup = build(:statistic_wrapup, owner: user )
    end

    it 'returns true if a wrapup owner has ocr corrections' do
      @wrapup.ocr_count = 2
      expect(@wrapup.ocr_corrections?).to be true
    end

    it 'returns false if a wrapup owner does not have ocr corrections' do
      @wrapup.ocr_count = 0
      expect(@wrapup.ocr_corrections?).to be false
    end
  end

  describe '#subjects_enabled?' do
    before :all do
     user = build_stubbed(:user)
     @wrapup = build(:statistic_wrapup, owner: user )
    end

    it 'returns true if a wrapup owner has subjects enabled' do
      allow(@wrapup.owner).to receive(:subjects_disabled).and_return(false)
      expect(@wrapup.subjects_enabled?).to be true
    end

    it 'returns false if a wrapup owner has subjects disabled' do
      allow(@wrapup.owner).to receive(:subjects_disabled).and_return(true)
      expect(@wrapup.subjects_enabled?).to be false
    end
  end
end
