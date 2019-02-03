require 'spec_helper'


RSpec.describe UserMailer::Activity do

  describe ".build" do
    before :all do
      @author = create(:user)
      @contributor = create(:user)
      @collection = create(:collection, owner_user_id: @author.id)
      @work = create(:work, collection_id: @collection.id)
      @page = create(:page, work_id: @work.id)
      @author_deed = create(:deed, {
        deed_type: DeedType::WORK_ADDED,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @author.id
      })
    end

    after :each do
      @contributor_deed.destroy if @contributor_deed
    end

    after :all do
      @author_deed.destroy
      @page.destroy
      @work.destroy
      @collection.destroy
      @author.destroy
      @contributor.destroy
    end

    it "stores the user as an attribute" do
      activity = UserMailer::Activity.build(@author)
      expect(activity.user).to eq(@author)
    end

    it "stores works added to a user's collection as an attribute" do
      @contributor_deed = create(:deed, {
        deed_type: DeedType::WORK_ADDED,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @contributor.id
      })
      activity = UserMailer::Activity.build(@author)
      expect(activity.added_works).to include(@work)
    end

    it 'stores pages with notes added as an attribute' do
      @contributor_deed = create(:deed, {
        deed_type: DeedType::NOTE_ADDED,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @contributor.id
      })
      activity = UserMailer::Activity.build(@author)
      expect(activity.active_note_pages).to include(@page)
    end

    it 'stores active pages as an attribute' do
      @contributor_deed = create(:deed, {
        deed_type: DeedType::PAGE_EDIT,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @contributor.id
      })
      activity = UserMailer::Activity.build(@author)
      expect(activity.active_pages).to include(@page)
    end

    it 'stores pages with recent translations as an attribute' do
      @contributor_deed = create(:deed, {
        deed_type: DeedType::PAGE_TRANSLATED,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @contributor.id
      })
      activity = UserMailer::Activity.build(@author)
      expect(activity.active_translations).to include(@page)
    end
  end


  describe '#has_contributons?' do
    before :all do
      @author = create(:user)
      @contributor = create(:user)
      @collection = create(:collection, owner_user_id: @author.id)
      @work = create(:work, collection_id: @collection.id)
      @page = create(:page, work_id: @work.id)
      @author_deed = create(:deed, {
        deed_type: DeedType::WORK_ADDED,
        page_id: @page.id,
        work_id: @work.id,
        collection_id: @collection.id,
        user_id: @author.id
      })
    end

    after :each do
      @contributor_deed.destroy if @contributor_deed
    end

    after :all do
      @author_deed.destroy
      @page.destroy
      @work.destroy
      @collection.destroy
      @author.destroy
      @contributor.destroy
    end

    context 'when it has added_works' do
      it 'returns true' do
        @contributor_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          page_id: @page.id,
          work_id: @work.id,
          collection_id: @collection.id,
          user_id: @contributor.id
        })
        activity = UserMailer::Activity.build(@author)
        expect(activity.has_contributions?).to be true
      end
    end

    context 'when it has active_pages' do
      it 'returns true' do
        @contributor_deed = create(:deed, {
          deed_type: DeedType::PAGE_EDIT,
          page_id: @page.id,
          work_id: @work.id,
          collection_id: @collection.id,
          user_id: @contributor.id
        })
        activity = UserMailer::Activity.build(@author)
        expect(activity.has_contributions?).to be true
      end
    end

    context 'when it has active_translations' do
      it 'returns true' do
        @contributor_deed = create(:deed, {
          deed_type: DeedType::PAGE_TRANSLATED,
          page_id: @page.id,
          work_id: @work.id,
          collection_id: @collection.id,
          user_id: @contributor.id
        })
        activity = UserMailer::Activity.build(@author)
        expect(activity.has_contributions?).to be true
      end
    end

    context 'when it has active_note_pages' do
      it 'returns true' do
        @contributor_deed = create(:deed, {
          deed_type: DeedType::NOTE_ADDED,
          page_id: @page.id,
          work_id: @work.id,
          collection_id: @collection.id,
          user_id: @contributor.id
        })
        activity = UserMailer::Activity.build(@author)
        expect(activity.has_contributions?).to be true
      end
    end

    context 'when it has no contributions' do
      it 'returns false' do
        activity = UserMailer::Activity.build(@author)
        expect(activity.has_contributions?).to be false
      end
    end
  end
end
