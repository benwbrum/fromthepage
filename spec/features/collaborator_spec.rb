require 'spec_helper'

describe 'Collaborator actions' do
  before :each do
    DatabaseCleaner.start
  end
  after :each do
    DatabaseCleaner.clean
  end

  let(:collaborator) { create(:user) }

  context 'when collection and docset are public' do
    let(:collection) { create(:collection) }
    let(:docset) { create(:document_set, :public) }
    let(:work) { collection.works.first }

    it 'can view public collections from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(collection.owner)
      expect(page).to have_content(collection.title)
    end

    it 'can view public document sets from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(docset.owner)
      expect(page).to have_content(docset.title)
    end

    it 'can view public collection page' do
      login_as(collaborator, scope: :user)
      visit collection_path(collection.owner, collection)
      expect(page.current_path).to eq(collection_path(collection.owner, collection))
    end

    it 'can view public works from collection page' do
      login_as(collaborator, scope: :user)
      visit collection_path(collection.owner, collection)
      expect(page).to have_content(work.title)
    end
  end

  context 'when collection is private and docset is public' do
    let(:private_collection) { create(:collection, :private) }
    let(:docset) do
      create(:document_set, :public,
        collection: private_collection,
        owner: private_collection.owner)
    end

    it 'cannot view private collections from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(private_collection.owner)
      expect(page).not_to have_content(private_collection.title)
    end

    it 'can view public docsets from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(docset.owner)
      expect(page).to have_content(docset.title)
    end
  end

  context 'when collection is public and docset is private' do
    let(:collection) { create(:collection) }
    let(:docset) do
      create(:document_set, :private,
        collection:,
        owner: collection.owner)
    end

    it 'can view public collections from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(collection.owner)
      expect(page).to have_content(collection.title)
    end

    it 'can view private docset from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(docset.owner)
      expect(page).not_to have_content(docset.title)
    end
  end

  context 'when collection is private and docset is private' do
    let(:collection) { create(:collection, :private) }
    let(:docset) do
      create(:document_set, :private,
        collection:,
        owner: collection.owner)
    end

    it 'cannot view private collections from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(collection.owner)
      expect(page).not_to have_content(collection.title)
    end

    it 'cannot view private docset from user profile' do
      login_as(collaborator, scope: :user)
      visit user_profile_path(docset.owner)
      expect(page).not_to have_content(docset.title)
    end

    context 'when added as a collaborator to a private collection' do
      let(:collection) do
        create(:collection, :private,
          collaborators: [collaborator])
      end
      let(:docset) do
        create(:document_set, :private,
          collection:,
          owner: collection.owner,
          owner_user_id: collection.owner.id)
      end

      it 'can view the private collection' do
        login_as(collaborator, scope: :user)
        visit user_profile_path(collection.owner)
        expect(page).to have_content(collection.title)
      end

      it 'can view private document sets, though not explicitly named' do
        login_as(collaborator, scope: :user)
        visit user_profile_path(docset.owner)
        expect(page).to have_content(docset.title)
      end
    end

    context 'when added as a collaborator to a private docset' do
      let(:collection) { create(:collection, :private) }
      let(:docset) do
        create(:document_set, :private,
          collection:,
          collaborators: [collaborator])
      end

      it 'cannot view private collections' do
        login_as(collaborator, scope: :user)
        visit user_profile_path(docset.owner)
        expect(page).not_to have_content(collection.title)
      end

      it 'can view private document sets' do
        login_as(collaborator, scope: :user)
        visit user_profile_path(docset.owner)
        expect(page).to have_content(docset.title)
      end
    end
  end
end
