require 'spec_helper'

RSpec.describe UserMailer::Activity do
  describe '#build' do
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
      @contributor_deed&.destroy
    end

    after :all do
      @author_deed.destroy
      @page.destroy
      @work.destroy
      @collection.destroy
      @author.destroy
      @contributor.destroy
    end

    it 'stores the user as an attribute' do
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
      @contributor_deed&.destroy
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
        activity_author = UserMailer::Activity.build(@author)
        expect(activity_author.has_contributions?).to be true

        activity_contributor = UserMailer::Activity.build(@contributor)
        expect(activity_contributor.has_contributions?).to be true
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
        activity_author = UserMailer::Activity.build(@author)
        expect(activity_author.has_contributions?).to be true

        activity_contributor = UserMailer::Activity.build(@contributor)
        expect(activity_contributor.has_contributions?).to be true
      end
    end

    context 'when it has added_works but contributor has no access' do
      it 'returns true for author, false for contributor' do
        @contributor_deed = create(:deed, {
          deed_type: DeedType::WORK_ADDED,
          page_id: @page.id,
          work_id: @work.id,
          collection_id: @collection.id,
          user_id: @contributor.id
        })

        @collection.update!(restricted: true)
        @work.update!(restrict_scribes: true)
        @work.scribes.delete(@contributor)

        activity_author = UserMailer::Activity.build(@author)
        expect(activity_author.has_contributions?).to be true

        activity_contributor = UserMailer::Activity.build(@contributor)
        expect(activity_contributor.has_contributions?).to be false
      end
    end

    context 'when it has no contributions' do
      it 'returns false' do
        activity_author = UserMailer::Activity.build(@author)
        expect(activity_author.has_contributions?).to be false

        activity_contributor = UserMailer::Activity.build(@contributor)
        expect(activity_contributor.has_contributions?).to be false
      end
    end
  end
end
